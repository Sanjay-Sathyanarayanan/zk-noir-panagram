// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Panagram} from "../src/Panagram.sol";
import {HonkVerifier} from "../src/Verifier.sol";

contract PanagramTest is Test {
    HonkVerifier public honkVerifier;
    Panagram public panagram;

    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    bytes32 constant GUESS_SINGLE_HASH = bytes32(uint256(keccak256(bytes("answer"))) % FIELD_MODULUS);
    bytes32 constant CORRECT_ANSWER_DOUBLE_HASH =
        bytes32(uint256(keccak256(abi.encodePacked(GUESS_SINGLE_HASH))) % FIELD_MODULUS);
    // User address for testing
    address user = makeAddr("user");

    bytes proof;

    function _getProof(bytes32 guess, bytes32 correctAnswer, address sender) internal returns (bytes memory _proof) {
        uint256 NUM_ARGS = 6;
        string[] memory inputs = new string[](NUM_ARGS);

        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.ts";
        inputs[3] = vm.toString(guess);
        inputs[4] = vm.toString(correctAnswer);
        inputs[5] = vm.toString(sender);

        bytes memory encodedProof = vm.ffi(inputs);
        (_proof) = abi.decode(encodedProof, (bytes));
    }

    function setUp() public {
        honkVerifier = new HonkVerifier();
        panagram = new Panagram(honkVerifier);

        panagram.newRound(CORRECT_ANSWER_DOUBLE_HASH);
        proof = _getProof(GUESS_SINGLE_HASH, CORRECT_ANSWER_DOUBLE_HASH, user);
    }

    function test_MakeCorrectGuess() public {
        vm.prank(user);
        panagram.makeGuess(proof);

        // Assertions
        vm.assertEq(panagram.balanceOf(user, 0), 1, "Winner NFT not minted"); // ID 0 for winner
        vm.assertEq(panagram.balanceOf(user, 1), 0, "Runner-up NFT wrongly minted for winner");

        // Test double spending/guessing
        vm.expectRevert();
        vm.prank(user);
        panagram.makeGuess(proof);
    }

    function test_StartNewRound() public {
        // start a round (in setUp)
        // get a winner
        vm.prank(user);
        panagram.makeGuess(proof);
        // min time passed
        vm.warp(panagram.MIN_DURATION() + 1);
        // start a new round
        panagram.newRound(
            bytes32(
                uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS))))
                    % FIELD_MODULUS
            )
        );
        // validate the state has reset
        vm.assertEq(
            panagram.getCurrentPanagram(),
            bytes32(
                uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS))))
                    % FIELD_MODULUS
            )
        );
        vm.assertEq(panagram.getCurrentRoundStatus(), address(0));
        vm.assertEq(panagram.s_currentRound(), 2);
    }

    function test_IncorrectGuessFails() public {
        bytes32 INCORRECT_ANSWER = bytes32(
            uint256(keccak256(abi.encodePacked(bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS))))
                % FIELD_MODULUS
        );
        bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS);
        // Generate a proof for an incorrect guess
        bytes memory incorrectProof = _getProof(INCORRECT_GUESS, INCORRECT_ANSWER, user);
        // Attempt to make a guess with the incorrect proof
        vm.prank(user);
        vm.expectRevert();
        panagram.makeGuess(incorrectProof);
    }

    function test_SecondWinnerPasses() public {
        address user2 = makeAddr("user2");
        vm.prank(user);
        panagram.makeGuess(proof);
        vm.assertEq(panagram.balanceOf(user, 0), 1);
        vm.assertEq(panagram.balanceOf(user, 1), 0);

        bytes memory proof2 = _getProof(GUESS_SINGLE_HASH, CORRECT_ANSWER_DOUBLE_HASH, user2);
        vm.prank(user2);
        panagram.makeGuess(proof2);
        vm.assertEq(panagram.balanceOf(user2, 0), 0);
        vm.assertEq(panagram.balanceOf(user2, 1), 1);
    }

    function test_RevertPanagramIfMinimumTimeNotPassed() public {
        // New round is already started in setUp
        // Attempt to start a new round before the minimum duration has passed
        vm.expectRevert(
            abi.encodeWithSelector(Panagram.Panagram__MinimumTimeNotPassed.selector, panagram.MIN_DURATION(), 0)
        );
        panagram.newRound(bytes32(uint256(keccak256("newanswer")) % FIELD_MODULUS));
    }

    function test_RevertIfNoWinnerYet() public {
        // Start a new round without any winner
        vm.warp(panagram.MIN_DURATION() + 1); // Ensure enough time has passed
        // Attempt to start a new round again without a winner
        vm.expectRevert(Panagram.Panagram__NoWinnerYet.selector);
        panagram.newRound(bytes32(uint256(keccak256("newAnswer")) % FIELD_MODULUS));
    }
}
