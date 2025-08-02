// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Panagram} from "../src/Panagram.sol";
import {HonkVerifier} from "../src/Verifier.sol";

contract PanagramTest is Test {
    HonkVerifier public honkVerifier;
    Panagram public panagram;

    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    bytes32 constant ANSWER = bytes32(uint256(keccak256(bytes("answer"))) % FIELD_MODULUS);
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

        panagram.newRound(ANSWER);
        proof = _getProof(ANSWER, ANSWER, user);
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
        panagram.newRound(bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS));
        // validate the state has reset
        vm.assertEq(panagram.getCurrentPanagram(), bytes32(uint256(keccak256("abcdefghi")) % FIELD_MODULUS));
        vm.assertEq(panagram.getCurrentRoundStatus(), address(0));
        vm.assertEq(panagram.s_currentRound(), 2);
    }

    function test_IncorrectGuessFails() public {
        bytes32 INCORRECT_ANSWER = bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS);
        bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("outnumber")) % FIELD_MODULUS);
        bytes memory incorrectProof = _getProof(INCORRECT_GUESS, INCORRECT_ANSWER, user);
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

        bytes memory proof2 = _getProof(ANSWER, ANSWER, user2);
        vm.prank(user2);
        panagram.makeGuess(proof2);
        vm.assertEq(panagram.balanceOf(user2, 0), 0);
        vm.assertEq(panagram.balanceOf(user2, 1), 1);
    }
}
