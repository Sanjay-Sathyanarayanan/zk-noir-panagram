// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVerifier} from "./Verifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Panagram is Ownable, ERC1155 {
    
    // State variables
    uint256 public constant MIN_DURATION = 3 hours;
    bytes32 public s_answer;
    uint256 public s_roundStartTime;
    uint256 public s_currentRound;

    address public s_currentRoundWinner;

    mapping(address => uint256) public s_lastCorrectGuessRound;

    IVerifier public s_verifier;

    // Errors
    error Panagram__MinimumTimeNotPassed(uint256 minimumTime, uint256 timePassed);
    error Panagram__NoWinnerYet();
    error Panagram__FirstPanagramNotSet();
    error Panagram__InvalidProof();
    error Panagram__AlreadyAnsweredCorrectlyInThisRound(address player, uint256 round);

    // Events

    event Panagram_VerifierUpdated(IVerifier verifier);
    event Panagram__NewRoundStarted(uint256 round, bytes32 answer);
    event Panagram_WinnerCrowned(address winner, uint256 round);
    event Panagram_RunnerUpCrowned(address runnerUp, uint256 round);

    constructor(IVerifier _verifier)
        ERC1155("ipfs://bafybeicg3hsuiokx6trzyezcznmf33gjxw6jmyhmkt4qyrnmeyhvymt5xy/{id}.json")
        Ownable(msg.sender)
    {
        s_verifier = _verifier;
    }

    /**
     * @notice Starts a new round of the Panagram game
     * @dev This function can only be called by the owner of the contract.
     * It checks if the minimum duration has passed since the last round started.
     * If the current round has a winner, it resets the round and sets a new answer.
     * If the round is being started for the first time, it initializes the round start time
     * @param _answer The answer to the current round in hash format
     */
    function newRound(bytes32 _answer) external onlyOwner {
        if (s_roundStartTime == 0) {
            s_roundStartTime = block.timestamp;
            s_answer = _answer;
        } else {
            if (block.timestamp < s_roundStartTime + MIN_DURATION) {
                revert Panagram__MinimumTimeNotPassed(MIN_DURATION, block.timestamp - s_roundStartTime);
            }

            if (s_currentRoundWinner == address(0)) {
                revert Panagram__NoWinnerYet();
            }

            // reset the round
            s_roundStartTime = block.timestamp;
            s_currentRoundWinner = address(0);
            s_answer = _answer;
        }
        s_currentRound++;

        emit Panagram__NewRoundStarted(s_currentRound, _answer);
    }

    function makeGuess(bytes memory _proof) external returns (bool) {
        if (s_currentRound == 0) {
            revert Panagram__FirstPanagramNotSet();
        }

        if (s_lastCorrectGuessRound[msg.sender] == s_currentRound) {
            revert Panagram__AlreadyAnsweredCorrectlyInThisRound(msg.sender, s_currentRound);
        }

        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = s_answer;
        publicInputs[1] = bytes32(uint256(uint160(msg.sender)));    // Convert address to bytes32

        bool result = s_verifier.verify(_proof, publicInputs);

        if (!result) {
            revert Panagram__InvalidProof();
        }

        s_lastCorrectGuessRound[msg.sender] = s_currentRound;
        if (s_currentRoundWinner == address(0)) {
            s_currentRoundWinner = msg.sender;
            _mint(msg.sender, 0, 1, ""); // Mint NFT ID 0 (Winner NFT)
            emit Panagram_WinnerCrowned(msg.sender, s_currentRound);
        } else {
            // Subsequent correct guess (runner-up)
            _mint(msg.sender, 1, 1, ""); // Mint NFT ID 1 (Participant NFT)
            emit Panagram_RunnerUpCrowned(msg.sender, s_currentRound);
        }

        return true;
    }

    function setVerifier(IVerifier _verifier) external onlyOwner {
        require(address(_verifier) != address(0), "Panagram: Verifier cannot be zero address");
        s_verifier = _verifier;
        emit Panagram_VerifierUpdated(_verifier);
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function getCurrentRoundStatus() external view returns (address) {
        return (s_currentRoundWinner);
    }

    function getCurrentPanagram() external view returns (bytes32) {
        return s_answer;
    }
}
