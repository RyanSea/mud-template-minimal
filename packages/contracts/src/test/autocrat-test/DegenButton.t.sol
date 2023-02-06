// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import { DegenButtonSystem } from "../../systems/DegenButtonSystem.sol";

import { TreasuryComponent, BalanceID, ID as TreasuryComponentID } from "../../components/TreasuryComponent.sol";
import { LastBlockComponent, LastBlockID, ID as LastBlockComponentID } from "../../components/LastBlockComponent.sol";

import { Uint256Component } from "solecs/components/Uint256Component.sol";
import { World } from "solecs/World.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";

contract DegenButtonTest is Test {
    World world;

    DegenButtonSystem button;

    TreasuryComponent treasury;
    LastBlockComponent lastBlock;

    address rite;
    address konata;
    address acheron;

    function setUp() public {
        _createWorld();
        _createComponents();
        _createButtonSystem();
        _createUsers();
    }

    event NewClick(address indexed sender, uint256 amount, uint totalTreasury);

    event NewWin(address indexed winner, uint256 payout);

    function testGame() public {
        // assert game hasn't started yet
        assertFalse(treasury.has(BalanceID));
        assertFalse(lastBlock.has(LastBlockID));

        vm.prank(rite);
        button.execute{ value: 1 ether}("");

        // assert components have updated correctly
        assertEq(treasury.getValue(BalanceID), 1 ether);
        assertEq(lastBlock.getValue(LastBlockID), 1);

        vm.roll(2);
        vm.prank(konata);

        // we expect a NewClick event as opposed to a win, because the block num has only increased by 2
        vm.expectEmit(true, false, false, true);
        emit NewClick(address(konata), 2 ether, 3 ether);

        button.execute{ value: 2 ether}("");

        // assert components have updated correctly
        assertEq(treasury.getValue(BalanceID), 3 ether);
        assertEq(lastBlock.getValue(LastBlockID), 2);

        vm.roll(5);
        vm.prank(acheron);

        uint balBefore = acheron.balance;

        // we expect a NewWin because the block has increased by 3 since the last block
        vm.expectEmit(true, false, false, true);
        emit NewWin(acheron, 4 ether);
        
        button.execute{ value: 1 ether}("");

        // assert payout successful
        assertEq(acheron.balance, balBefore + 3 ether);

        // assert game reset
        assertFalse(treasury.has(BalanceID));
        assertFalse(lastBlock.has(LastBlockID));
    }

    function _createWorld() internal {
        world = new World();
        world.init();
    }

    function _createComponents() internal {
        treasury = new TreasuryComponent(address(world));
        lastBlock = new LastBlockComponent(address(world));
    }

    function _createButtonSystem() internal {
        // create button's register component
        Uint256Component registerComponent = new Uint256Component(
            address(world), 
            uint256(keccak256("system.DegenButton.register"))
        );

        // create button
        button = new DegenButtonSystem(IWorld(address(world)), address(registerComponent));

        // authorize button to write to its register component
        registerComponent.authorizeWriter(address(button));

        // add components to register note: setting by uint256(address) => ID, and not the other way around, is
        //                                  super counterintuitive and I hate it, but that seems to be the standard
        registerComponent.set(uint256(uint160(address(treasury))), TreasuryComponentID);
        registerComponent.set(uint256(uint160(address(lastBlock))), LastBlockComponentID);  

        // authorize button to write to components
        treasury.authorizeWriter(address(button));
        lastBlock.authorizeWriter(address(button));
    }

    function _createUsers() internal {
        address[] memory users = new address[](3);

        for (uint i; i < 3; ) {
            users[i] = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
            vm.deal(users[i], 10000 ether);

            unchecked { ++i; }
        }

        rite = users[0];
        konata = users[1];
        acheron = users[2];
    }
}




