// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Bootstrap} from "test/utils/Bootstrap.sol";

contract SMv3SessionValidationModuleTest is Bootstrap {
    function setUp() public {
        initializeOptimismGoerli();
    }
}

contract ValidateSessionParams is SMv3SessionValidationModuleTest {
    function test_validateSessionParams() public {
        assertTrue(false);
    }

    function test_validateSessionParams_destinationContract() public {
        assertTrue(false);
    }

    function test_validateSessionParams_callValue() public {
        assertTrue(false);
    }

    function test_validateSessionParams_funcCallData() public {
        assertTrue(false);
    }

    function test_validateSessionParams_sessionKeyData() public {
        assertTrue(false);
    }

    function test_validateSessionParams_callSpecificData() public {
        assertTrue(false);
    }
}

contract ValidateSessionUserOp is SMv3SessionValidationModuleTest {
    function test_validateSessionUserOp() public {
        assertTrue(false);
    }

    function test_validateSessionUserOp_op() public {
        assertTrue(false);
    }

    function test_validateSessionUserOp_userOpHash() public {
        assertTrue(false);
    }

    function test_validateSessionUserOp_sessionKeyData() public {
        assertTrue(false);
    }

    function test_validateSessionUserOp_sessionKeySignature() public {
        assertTrue(false);
    }
}
