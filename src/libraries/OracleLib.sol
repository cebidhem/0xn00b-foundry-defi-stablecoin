// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author cebidhem
 * @notice This lib is uysed to check the Chainlink Oracle for stale data
 * If a price is stale, the function will revert, and render the DSCEngine unusable - this is by design
 * We want the DSCEngin to freeze is prices become stale
 *
 * So if the Chainlink network explodes and you have a lot of money locked in the protocol... you're screwed
 */
library OracleLib {
    error OracleLib__StalePrice();

    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        (uint80 roundID, int256 price, uint256 startedAt, uint256 timestamp, uint80 answeredInRound) =
            priceFeed.latestRoundData();

        uint256 secondsSince = block.timestamp - timestamp;
        if (secondsSince > TIMEOUT) revert OracleLib__StalePrice();

        return (roundID, price, startedAt, timestamp, answeredInRound);
    }
}
