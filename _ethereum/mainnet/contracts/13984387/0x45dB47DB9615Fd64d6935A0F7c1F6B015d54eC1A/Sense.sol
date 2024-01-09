// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

///  ________         _____                         
/// /_  __/ /  ___   / ___/__  __ _  __ _  ___  ___ 
///  / / / _ \/ -_) / /__/ _ \/  ' \/  ' \/ _ \/ _ \
/// /_/ /_//_/\__/  \___/\___/_/_/_/_/_/_/\___/_//_/                                                
///      ____                   _  ____________
///     / __/__ ___  ___ ___   / |/ / __/_  __/
///    _\ \/ -_) _ \(_-</ -_) /    / _/  / /   
///   /___/\__/_//_/___/\__/ /_/|_/_/   /_/    
                                                        

import "./ERC721Enumerable.sol";


contract Sense is ERC721Enumerable {
    constructor()
        ERC721(
            "The Common Sense NFT",
            "SENSE"
        )
    {
    }


    function mint() external payable {
        uint count = totalSupply();

        require(
            count < MAX_SUPPLY,
            "Mint closed"
        );

        address msgSender = _msgSender();

        require(
            addressMinted[msgSender] == false,
            "Max 1 mint per address"
        );

        require(
            msg.value == MINT_PRICE,
            "Price per mint: 0.01 ETH"
        );

        addressMinted[msgSender] = true;
        _mint(msgSender, count+1);
    }


    function setMetadataURI(string calldata uri) external
        onlyController()
    {
        metadataURI = uri;
        metadataSet = true;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "Nonexistent token"
        );

        if (metadataSet) {
            return metadataURI;
        }

        return PLACEHOLDER_URI;
    }


    function payout() external
        onlyController()
    {

        (bool sent,) = payable(_msgSender()).call{value: address(this).balance}("");
        require(
            sent,
            "TX failed"
        );
    }


    modifier onlyController() {
        require(
           _msgSender() == 0x6e4F767278f5E3b4d25C80e89e277d50A66D1abE,
            "Invalid requester"
        );
        _;
    }


    uint constant public MAX_SUPPLY         = 10000;
    uint constant public MINT_PRICE         = 1 * 1e16;

    string constant private PLACEHOLDER_URI = 'http://the-common-sense-nft.s3-website-us-east-1.amazonaws.com/';
    string private metadataURI              = '';
    bool private metadataSet                = false;

    mapping(address => bool) private addressMinted;
}
