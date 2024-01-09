// SPDX-License-Identifier: MIT

//                         ___           ___           ___
//             ___        /  /\         /__/|         /  /\
//            /  /\      /  /::\       |  |:|        /  /:/_
//           /  /:/     /  /:/\:\      |  |:|       /  /:/ /\
//          /  /:/     /  /:/  \:\   __|  |:|      /  /:/ /:/_
//         /  /::\    /__/:/ \__\:\ /__/\_|:|____ /__/:/ /:/ /\
//        /__/:/\:\   \  \:\ /  /:/ \  \:\/:::::/ \  \:\/:/ /:/
//        \__\/  \:\   \  \:\  /:/   \  \::/~~~~   \  \::/ /:/
//             \  \:\   \  \:\/:/     \  \:\        \  \:\/:/
//              \__\/    \  \::/       \  \:\        \  \::/
//                        \__\/         \__\/         \__\/
//             ___           ___           ___          _____          ___
//            /__/\         /  /\         /__/\        /  /::\        /  /\
//            \  \:\       /  /::\        \  \:\      /  /:/\:\      /  /:/_
//             \__\:\     /  /:/\:\        \  \:\    /  /:/  \:\    /  /:/ /\
//         ___ /  /::\   /  /:/~/::\   _____\__\:\  /__/:/ \__\:|  /  /:/ /::\
//        /__/\  /:/\:\ /__/:/ /:/\:\ /__/::::::::\ \  \:\ /  /:/ /__/:/ /:/\:\
//        \  \:\/:/__\/ \  \:\/:/__\/ \  \:\~~\~~\/  \  \:\  /:/  \  \:\/:/~/:/
//         \  \::/       \  \::/       \  \:\  ~~~    \  \:\/:/    \  \::/ /:/
//          \  \:\        \  \:\        \  \:\         \  \::/      \__\/ /:/
//           \  \:\        \  \:\        \  \:\         \__\/         /__/:/
//            \__\/         \__\/         \__\/                       \__\/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TOKEHANDS is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;

    string private untattoedUri = "";
    string private tattooedUri = "";
    address private devPayoutAddress;
    address private ownerPayoutAddress;

    uint256 public cost = 0.11 ether;
    uint256 public maxSupply = 100;

    uint256 private saleDate = 1643572800; // 1/30/22 @ 3:00pm ET
    mapping(uint256 => bool) public redeemedForTattoo;

    constructor() ERC721("TOKEHANDS", "TKHN") {
        setUntattooedUri(
            "ipfs://QmPMvC3qY2YsVq98xXHNdGT1bCe4Hi1TsdgiBenef4Uowk/"
        );
        setTattoedUri("ipfs://Qmc9BcjwDwbqGRnKG3dED4f2yWaACp76WNV8FUeKvSyuiT/");
    }

    event NewTokeHandMinted(address sender, uint256 tokenId);

    function maxPerWallet() public view returns (uint256) {
        if (saleDate + 1 days >= block.timestamp) {
            return 1;
        } else {
            return 5;
        }
    }

    // Mint Functions
    modifier mintCompliance(address _sender, uint256 _mintAmount) {
        if (supply.current() + _mintAmount > maxSupply) {
            revert("Would sell out");
        }
        _;
    }

    function mint(uint256 _qty)
        public
        payable
        mintCompliance(msg.sender, _qty)
    {
        uint256 ownerTokenCount = balanceOf(msg.sender);
        if (!isMintActive()) revert("Not yet on sale");
        if (ownerTokenCount + _qty > maxPerWallet())
            revert("You already hold max TOKEHANDS per wallet");
        if (msg.value < cost * _qty)
            revert("Not enough ether sent with transaction");
        _mintLoop(msg.sender, _qty);
    }

    function mintForAddresses(address[] memory _receivers) public onlyOwner {
        if (_receivers.length > 5) revert("Max 5 giveaway");
        if (supply.current() + _receivers.length > maxSupply)
            revert("Minting this many will sell out collection");
        for (uint256 i = 0; i < _receivers.length; i++) {
            _mintLoop(_receivers[i], 1);
        }
    }

    function setUntattooedUri(string memory _uri) public onlyOwner {
        untattoedUri = _uri;
    }

    function setTattoedUri(string memory _uri) public onlyOwner {
        tattooedUri = _uri;
    }

    function setDevAddress(address _devAddress) public onlyOwner {
        devPayoutAddress = _devAddress;
    }

    function setOwnerPayoutAddress(address _ownerPayoutAddress)
        public
        onlyOwner
    {
        ownerPayoutAddress = _ownerPayoutAddress;
    }

    function redeemByIds(uint256[] memory _tokehandsIds) public {
        if (!isMintActive()) revert("Claiming is not active at the moment");
        for (uint256 i = 0; i < _tokehandsIds.length; i++) {
            address tokeHandOwner = ownerOf(_tokehandsIds[i]);
            if (!_exists(_tokehandsIds[i])) revert();
            if (tokeHandOwner != msg.sender) revert("You do not own the token");
            if (redeemedForTattoo[_tokehandsIds[i]])
                revert("token already been claimed");
        }
        for (uint256 i = 0; i < _tokehandsIds.length; i++) {
            redeemedForTattoo[_tokehandsIds[i]] = true;
        }
    }

    // Public get Fns

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = ownerPayoutAddress;
        royaltyAmount = (salePrice * 500) / 10_000; // 5% royalty
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function isMintActive() public view returns (bool) {
        return block.timestamp >= saleDate;
    }

    function hasTokenBeenRedeemed(uint256 _tokenId) public view returns (bool) {
        return redeemedForTattoo[_tokenId];
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert();
        if (!isMintActive()) {
            return "ipfs://QmQoNKYcn1NyTAqiJKDMAkLxsXJ8hLmbdRgimA5iGjFi5v";
        }

        if (redeemedForTattoo[_tokenId] == true) {
            string memory currentRedeemedUri = _tattoedUri();
            return
                bytes(currentRedeemedUri).length > 0
                    ? string(
                        abi.encodePacked(
                            currentRedeemedUri,
                            _tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    // Withdraw
    function withdraw() public onlyOwner {
        if (devPayoutAddress == address(0) || ownerPayoutAddress == address(0))
            revert();
        if (address(this).balance == 0) revert("no balance in contract");
        // dev 5% of the initial sale.
        (bool devPayout, ) = payable(devPayoutAddress).call{
            value: (address(this).balance * 5) / 100
        }("");
        if (!devPayout) revert("Dev payout failed");

        // Remaining to owner
        (bool ownerPayout, ) = payable(ownerPayoutAddress).call{
            value: address(this).balance
        }("");
        if (!ownerPayout) revert("Owner payout failed");
    }

    // Internal Fns

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
            emit NewTokeHandMinted(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return untattoedUri;
    }

    function _tattoedUri() internal view virtual returns (string memory) {
        return tattooedUri;
    }
}
