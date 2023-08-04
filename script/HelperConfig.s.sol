// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { MockV3Aggregator } from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMAILS = 8;
    int public constant INITIAL_NUMBER = 2000e8;

    struct NetworkConfig {
        address priceFeedAddress;
    }

    constructor() {
        if( block.chainid == 11155111 ) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    function getOrCreateAnvilConfig() public returns(NetworkConfig memory) {
        if( activeNetworkConfig.priceFeedAddress != address(0) )
        {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMAILS, INITIAL_NUMBER);
        vm.stopBroadcast();

        return NetworkConfig({
            priceFeedAddress: address(mockPriceFeed)
        });
    }
}