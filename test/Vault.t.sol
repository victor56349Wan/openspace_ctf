// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";




contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    AttackVault  public attacker;
    address owner = address (1);
    address palyer = address (2);
    

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposit{value: 0.1 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);
        attacker = new AttackVault(vault, logic);
        attacker.attack{value: 0.05 ether}();
        vm.stopPrank();

        // add your hacker code.

        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}
