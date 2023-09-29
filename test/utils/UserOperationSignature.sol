// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {
    UserOperation,
    UserOperationLib
} from "src/biconomy/interfaces/UserOperation.sol";
import {ECDSA} from "src/openzeppelin/ECDSA.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";

contract UserOperationSignature {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;

    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getUserOperationSignature(
        UserOperation calldata op,
        uint256 privateKey
    ) public returns (bytes memory sig) {
        bytes32 hash = hashUserOperation(op).toEthSignedMessageHash();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);

        return bytes.concat(r, s, bytes1(v));
    }

    function hashUserOperation(UserOperation calldata op)
        public
        pure
        returns (bytes32)
    {
        return op.hash();
    }
}
