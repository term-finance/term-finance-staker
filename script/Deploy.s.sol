// SPDX-License-Identifier: AGPL-3.0-only
// slither-disable-start reentrancy-benign

pragma solidity 0.8.23;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";

import {TermStaker} from "src/TermStaker.sol";
import {V3FactoryOwner} from "src/V3FactoryOwner.sol";
import {IERC20Delegates} from "src/interfaces/IERC20Delegates.sol";
import {INotifiableRewardReceiver} from "src/interfaces/INotifiableRewardReceiver.sol";
import {IUniswapV3FactoryOwnerActions} from "src/interfaces/IUniswapV3FactoryOwnerActions.sol";

contract Deploy is Script {
  function run() public returns (V3FactoryOwner, UniStaker) {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address STAKE_TOKEN_ADDRESS = vm.envAddress("STAKE_TOKEN_ADDRESS");
    address PAYOUT_TOKEN_ADDRESS = vm.envAddress("PAYOUT_TOKEN_ADDRESS");

    vm.startBroadcast(deployerPrivateKey);
    // Deploy the staking contract
    UniStaker uniStaker = new UniStaker(
      IERC20(PAYOUT_TOKEN_ADDRESS),
      IERC20Delegates(STAKE_TOKEN_ADDRESS),
      vm.addr(deployerPrivateKey)
    );

    // Deploy a new owner for the V3 factory owner actions contract.
    V3FactoryOwner v3FactoryOwner = new V3FactoryOwner(
      UNISWAP_GOVERNOR_TIMELOCK,
      IUniswapV3FactoryOwnerActions(UNISWAP_V3_FACTORY_ADDRESS),
      IERC20(PAYOUT_TOKEN_ADDRESS),
      PAYOUT_AMOUNT,
      INotifiableRewardReceiver(uniStaker)
    );

    // Enable the v3FactoryOwner as a UniStaker reward notifier
    uniStaker.setRewardNotifier(address(v3FactoryOwner), true);

    // Change UniStaker admin from `msg.sender` to the Governor timelock
    uniStaker.setAdmin(UNISWAP_GOVERNOR_TIMELOCK);
    vm.stopBroadcast();

    return (v3FactoryOwner, uniStaker);
  }
}
