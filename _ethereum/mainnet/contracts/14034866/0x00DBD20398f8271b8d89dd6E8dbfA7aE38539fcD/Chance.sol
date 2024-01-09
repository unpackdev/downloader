// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


///    ________                             _   ______________
///   / ____/ /_  ____ _____  ________     / | / / ____/_  __/
///  / /   / __ \/ __ `/ __ \/ ___/ _ \   /  |/ / /_    / /   
/// / /___/ / / / /_/ / / / / /__/  __/  / /|  / __/   / /    
/// \____/_/ /_/\__,_/_/ /_/\___/\___/  /_/ |_/_/     /_/     


import "./ERC721Enumerable.sol";


contract Chance is ERC721Enumerable {
    constructor()
        ERC721(
            "Chance NFT",
            "CHANCE"
        )
    {
    }


    function mint(uint8 numNFTs) external payable {
        // Mint 1-2 NFTs
        require(numNFTs > 0 && numNFTs <= MAX_MINTS_PER_ADDRESS,
            MAX_MINTS_PER_ADDRESS_TEXT
        );

        address msgSender = _msgSender();

        // Check max. mints per address
        require(
            numMinted[msgSender] + numNFTs <= MAX_MINTS_PER_ADDRESS,
            MAX_MINTS_PER_ADDRESS_TEXT
        );

        uint count = totalSupply();

        // Check mint availability
        require(
            count + numNFTs <= MAX_SUPPLY,
            "<numNFTs> NFTs not available"
        );

        // Check mint price
        require(
            msg.value == MINT_PRICE * numNFTs,
            "Price per NFT: 0.042 ETH"
        );

        numMinted[msgSender] += numNFTs;

        _mint(msgSender, count+1);

        // Less gas than for-loop for max. 2 iterations
        if (numNFTs == 2) {
            _mint(msgSender, count+2);
        }
    }


    function setMetadataURI(string calldata uri) external
        onlyController()
    {
        metadataURI = uri;
        metadataSet = true;
    }


    function contractURI() public pure returns (string memory) {
        return CONTRACT_URI;
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
        (bool sent,) = CONTROLLER.call{value: address(this).balance}("");
        require(
            sent,
            "TX failed"
        );
    }


    modifier onlyController() {
        require(
           _msgSender() == CONTROLLER,
            "Invalid requester"
        );
        _;
    }


    uint constant public MAX_SUPPLY                    = 4242;
    uint constant public MAX_MINTS_PER_ADDRESS         = 2;
    string constant private MAX_MINTS_PER_ADDRESS_TEXT = "Max. 2 mints per address";
    uint constant public MINT_PRICE                    = 42 * 1e15;

    string constant private CONTRACT_URI        = 'https://bafkreidginxwf3q4ejc7pz66ztwyvkakafape5nk3qo6sp5ulhiepnf6be.ipfs.dweb.link/';
    string constant private PLACEHOLDER_URI     = 'https://bafkreib6v334ua5g5t7x3xdncrfums64y5x3sjoqu3irgflrselm5dlq2m.ipfs.dweb.link/';
    string private metadataURI                  = '';
    bool private metadataSet                    = false;

    address payable private constant CONTROLLER = payable(0x6e4F767278f5E3b4d25C80e89e277d50A66D1abE);
    mapping(address => uint8) private numMinted;
}
