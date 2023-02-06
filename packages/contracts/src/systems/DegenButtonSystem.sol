// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { 
  PayableSystem, 
  IWorld, 
  IUint256Component 
} from "solecs/PayableSystem.sol";

import { ID as TreasuryComponentID, BalanceID } from "components/TreasuryComponent.sol";
import { ID as LastBlockComponentID, LastBlockID } from "components/LastBlockComponent.sol";

import { getAddressById } from "solecs/utils.sol";

uint256 constant ID = uint256(keccak256("system.DegenButton"));

/// @title Degen Button
/// @notice solidity MUD implementation of Reddit's The Button
contract DegenButtonSystem is PayableSystem {
  constructor(IWorld _world, address _components) PayableSystem(_world, _components) {}

  event NewClick(address indexed sender, uint256 amount, uint totalTreasury);

  event NewWin(address indexed winner, uint256 payout);

  /// @notice executes a button click — either updating last block & treasury components
  ///         or paying out winnings and resetting components
  function execute(bytes memory) public payable returns (bytes memory idk) {
    require(msg.value >= 0.01 ether, "MINIMUM_UNMET");

    // review: not sure what to return
    idk = "";

    IUint256Component treasuryComponent = IUint256Component(
      getAddressById(components, TreasuryComponentID)
    );

    IUint256Component lastBlockComponent = IUint256Component(
      getAddressById(components, LastBlockComponentID)
    );

    uint256 currentTreasury = treasuryComponent.has(BalanceID) ? 
      treasuryComponent.getValue(BalanceID) : 0;

    uint256 lastBlock = lastBlockComponent.has(LastBlockID) ? 
      lastBlockComponent.getValue(LastBlockID) : block.number;

    uint256 totalTreasury = msg.value + currentTreasury;

    // if 3+ blocks have past since last block, reset game & payout winner
    if (lastBlock + 3 <= block.number) {
      treasuryComponent.remove(BalanceID);
      lastBlockComponent.remove(LastBlockID);

      (bool success, ) = msg.sender.call{ value : totalTreasury }("");
      require(success, "UNSUCCESSFUL_PAYOUT");

      emit NewWin(msg.sender, totalTreasury);

    // else update game
    } else {
      treasuryComponent.set(BalanceID, totalTreasury);
      lastBlockComponent.set(LastBlockID, block.number);

      emit NewClick(msg.sender, msg.value, totalTreasury);
    }
  }

 
}
