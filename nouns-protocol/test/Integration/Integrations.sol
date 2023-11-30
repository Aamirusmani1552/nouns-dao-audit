// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Treasury } from "../../src/governance/treasury/Treasury.sol";
import { Auction } from "../../src/auction/Auction.sol";
import { IAuction } from "../../src/auction/IAuction.sol";
import { Token } from "../../src/token/Token.sol";
import { MetadataRenderer } from "../../src/token/metadata/MetadataRenderer.sol";
import { Governor } from "../../src/governance/governor/Governor.sol";
import { IManager } from "../../src/manager/IManager.sol";
import { Manager } from "../../src/manager/Manager.sol";
import { UUPS } from "../../src/lib/proxy/UUPS.sol";
import { TokenTypesV2 } from "../../src/token/types/TokenTypesV2.sol";
import { GovernorTypesV1 } from "../../src/governance/governor/types/GovernorTypesV1.sol";
import { Test } from "forge-std/Test.sol";
import { ERC1967Proxy } from "../../src/lib/proxy/ERC1967Proxy.sol";
import { NounsBuilderTest } from "../utils/NounsBuilderTest.sol";
import { console2 } from "forge-std/console2.sol";

contract MockMetadataRender {
    address public _token;

    function initialize(string memory initStrings, address token) public {
        _token = token;
    }

    function onMinted() public returns (bool success) {
        return true;
    }
}

contract MockTreasury {
    function initialize(address governor, uint256 timelockDelay) public { }
}

contract MockGovernor {
    function initialize(
        address treasury,
        address token,
        address vetoer,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 proposalThresholdBps,
        uint256 quorumThresholdBps
    ) public { }
}

contract Integrations is NounsBuilderTest {
    address public founderRewardsRecipient = makeAddr("founderRewardsRecipient");
    uint256 public numOfFounders = 1;

    // users
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public override {
        super.setUp();
    }

    function test_updatingThefoundersMappingWillNotRemoveAnyFoundersInHundreds() public {
        // setting up everything
        deployMock();

        // getting the number of founders info
        uint256 foundersAdded = token.totalFounders();

        // checking the number of founders. should be 1
        assertEq(numOfFounders, foundersAdded);

        // updating the founders
        IManager.FounderParams[] memory newFoundersArr = new IManager.FounderParams[](2);
        newFoundersArr[0] = IManager.FounderParams({ wallet: address(makeAddr("newFounder1")), ownershipPct: 0, vestExpiry: 2556057600 });
        newFoundersArr[1] = IManager.FounderParams({ wallet: address(makeAddr("newFounder2")), ownershipPct: 10, vestExpiry: 2556057600 });

        vm.prank(token.owner());
        token.updateFounders(newFoundersArr);

        assertEq(token.getFounders().length, 1);
    }

    function setMockFounderParams() internal override {
        require(numOfFounders == 1 || numOfFounders == 10, "invalid number of founders");
        address[] memory wallets = new address[](numOfFounders);
        uint256[] memory vestingEnds = new uint256[](numOfFounders);
        uint256[] memory percents = new uint256[](numOfFounders);

        // setting up the founder params
        if (numOfFounders == 1) {
            percents[0] = 1;
        } else {
            // max percent = 99
            percents[0] = 10;
            percents[1] = 5;
            percents[2] = 5;
            percents[3] = 3;
            percents[4] = 7;
            percents[5] = 8;
            percents[6] = 2;
            percents[7] = 1;
            percents[8] = 9;
            percents[9] = 49;
        }

        for (uint8 i; i < numOfFounders; i++) {
            wallets[i] = address(uint160(i + 1));
            vestingEnds[i] = 4 weeks;
        }

        setFounderParams(wallets, percents, vestingEnds);
    }

    function setMockTokenParams() internal override {
        setTokenParams(
            "Mock Token",
            "MOCK",
            "This is a mock token",
            "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j",
            "https://nouns.build",
            "http://localhost:5000/render",
            200, // _reservedUntilTokenId: this was zero before
            address(0)
        );
    }
}
