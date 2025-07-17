// SPDX-License-Identifier: MIT
​
pragma solidity ^0.8.24;
import {IVerifier} from "./Verifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract  Panagram is Ownable {

    IVerifier public immutable i_verifier;

    // Events

    event Panagram_VerifierUpdated(IVerifier verifier);

    constructor(IVerifier _verifier) Ownable(msg.sender) {
        i_verifier = _verifier;
    }

    function setVerifier(IVerifier _verifier) external onlyOwner {
        require(address(_verifier) != address(0), "Panagram: Verifier cannot be zero address");
        i_verifier = _verifier;
        emit Panagram_VerifierUpdated(_verifier);
    }


}

