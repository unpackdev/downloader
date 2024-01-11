// SPDX-License-Identifier: Apache License 2.0
// --______-----------_____-----------------_----------------------------------_------------------------_----
// -|--____|---------|--__-\---------------|-|--------------------------------|-|----------------------|-|---
// -|-|__-___--_-__--|-|--|-|-_____---_____|-|-___--_-__--_-__-___---___-_-__-|-|_--__------_____--_-__|-|-__
// -|--__/-_-\|-'__|-|-|--|-|/-_-\-\-/-/-_-\-|/-_-\|-'_-\|-'_-`-_-\-/-_-\-'_-\|-__|-\-\-/\-/-/-_-\|-'__|-|/-/
// -|-|-|-(_)-|-|----|-|__|-|--__/\-V-/--__/-|-(_)-|-|_)-|-|-|-|-|-|--__/-|-|-|-|_---\-V--V-/-(_)-|-|--|---<-
// -|_|__\___/|_|----|_____/-\___|-\_/-\___|_|\___/|-.__/|_|-|_|-|_|\___|_|-|_|\__|---\_/\_/-\___/|_|--|_|\_\
// --/-____|----------|-|-----------|-|------------|-|-------------------------------------------------------
// -|-|-----___--_-__-|-|_-__-_--___|-|_---_-__-___|_|___----------------------------------------------------
// -|-|----/-_-\|-'_-\|-__/-_`-|/-__|-__|-|-'_-`-_-\-/-_-\---------------------------------------------------
// -|-|___|-(_)-|-|-|-|-||-(_|-|-(__|-|_--|-|-|-|-|-|--__/---------------------------------------------------
// --\_____\___/|_|-|_|\__\__,_|\___|\__|-|_|-|_|-|_|\___|---------------------- https://duncanpeach.com/ ---
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------

pragma solidity ^0.8.14;

import "AggregatorV3Interface.sol";
import "ERC721URIStorage.sol";
import "Counters.sol";

contract TipThankyouNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string[] private PossibleNFTS;

    AggregatorV3Interface internal USDETHFeed;
    uint256 internal minimalTipPriceinWei;
    address payable internal TipsWallet;

    mapping(address => uint256) internal Tips;
    address[] internal Tippers;

    constructor(string[] memory _PossibleNFTS, address _USDETHFeed)
        ERC721("Thank you Cards", "GratitudeCards")
    {
        minimalTipPriceinWei = 50 * (10**18);
        TipsWallet = payable(msg.sender);
        USDETHFeed = AggregatorV3Interface(_USDETHFeed);
        PossibleNFTS = _PossibleNFTS;
    }

    function CreateThankyouNFT() internal {
        string memory NFTChosenType = PossibleNFTS[GetRandom_ISH_NFT()];
        _tokenIds.increment();
        uint256 TokenID = _tokenIds.current();

        _safeMint(msg.sender, TokenID);
        _setTokenURI(TokenID, NFTChosenType);
    }

    function GetRandom_ISH_NFT() internal returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.difficulty,
                        block.timestamp
                    )
                )
            ) % uint256(PossibleNFTS.length);
    }

    function sendTipForNFT() public payable {
        require(
            msg.value >= getPriceInWei(),
            "Not Enough for NFT, $50 minimal eth "
        );
        Tips[msg.sender] += msg.value;
        Tippers.push(msg.sender);
        CreateThankyouNFT();
    }

    function getminimalTipPriceinWei() public view returns (uint256) {
        return (minimalTipPriceinWei);
    }

    function getPriceInWei() public view returns (uint256) {
        return (getminimalTipPriceinWei() / getEthPriceInGWei()) * (10**9);
    }

    function getEthPriceInGWei() public view returns (uint256) {
        (, int256 EthPrice, , , ) = USDETHFeed.latestRoundData();
        return uint256(EthPrice);
    }

    modifier onlyOwner() {
        require(msg.sender == TipsWallet);
        _;
    }

    function withdraw() public onlyOwner {
        TipsWallet.transfer(address(this).balance);
        for (
            uint256 TipperIndex = 0;
            TipperIndex < Tippers.length;
            TipperIndex++
        ) {
            address Tipper = Tippers[TipperIndex];
            Tips[Tipper] = 0;
        }
        Tippers = new address[](0);
    }
}
