// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol"; 
import {CryptoBank} from "../src/bank.sol";

contract CryptoBankTest is Test {
    CryptoBank public cryptoBank;

    function setUp() public {
        address owner = address(this);
        uint256 interestRate = 500; // 5%
        cryptoBank = new CryptoBank(owner, interestRate);
    }

    // Ejemplo de test
    uint256 public lastDepositAmount;

    function testDepositETH() public {
        uint256 depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);

        cryptoBank.depositETH{value: depositAmount}();

        assertGe(cryptoBank.ethBalances(address(this)), depositAmount);
        assertGe(cryptoBank.ethBalances(address(this)), depositAmount);
       

        // Store depositAmount as a state variable
        lastDepositAmount = depositAmount;
    }


    function testWithdrawETH() public {
    uint256 depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);

        cryptoBank.depositETH{value: depositAmount}();

    // Ahora retirar ese mismo monto
    cryptoBank.withdrawETH(depositAmount);

    // Comprobamos que el balance del contrato volvió a 0
    assertEq(address(cryptoBank).balance, 0);
    
}

    function testSetInterestRate() public {
        uint256 newRate = 600; // 6%
        cryptoBank.setInterestRate(newRate);

        assertEq(cryptoBank.interestRate(), newRate);
    }
    function testPause() public {
        cryptoBank.pause();

        // Check if the contract is paused
        assertTrue(cryptoBank.paused());
    }
    function testUnpause() public {
    cryptoBank.pause();      // Pausás el contrato primero
    cryptoBank.unpause();    // Ahora sí, lo despausás
    assertFalse(cryptoBank.paused());
}

    receive() external payable {}


    }
