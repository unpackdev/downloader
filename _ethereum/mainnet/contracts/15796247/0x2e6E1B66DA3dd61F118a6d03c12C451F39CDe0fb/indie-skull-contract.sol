// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract skullSyndicate is ERC721A, Ownable {
    uint256 internal MAX_MINTS = 5;
    uint256 internal Public_Mints;
    uint256 internal Skull_Mints;
    uint256 internal WL_Mints;
    uint256 internal MAX_SUPPLY = 2500;
    uint256 internal mint_Price = 0.005 ether;
    uint256 internal skull_List_Mint_Price = 0.002 ether;
    // Time stamps for minting
    uint32 internal Skull_List_Time = 1666371600;
    uint32 internal whiteList_Time = 1666375200;
    uint32 internal end_of_WL_mint = 1666382400;
    uint32 internal mint_Time = 1666378800;
    /////////////////////////////
    address internal DeveloperAddress =
        0xB96DfC3e4cBE9Da6F072d57c13b5EfB44c8b192C;
    address internal OwnerAddress = 0xb328200EcA7C688646af1c8Bb25b6e9B8ed11368;
    // address internal collabAddress = 0xfbEeeB35Cb3c94861b7EdC5Fe460EfDca9716F19;
    uint96 internal royaltyFeesInBips;
    address internal royaltyReceiver;
    uint256 internal amount;
    string internal contractURI;
    bytes32 internal whiteList_root;
    bytes32 internal skull_root;
    bool internal checkWL;
    bool internal checkSkull;

    string internal baseURI =
        "https://indieskullsyndicate.mypinata.cloud/ipfs/QmSxZtEkRcBdWL9S7nEBP335Bc6TNMm6H9nmFXdq6VVUsH/";

    constructor(
        uint96 _royaltyFeesInBips,
        string memory _contractURI,
        bytes32 _whiteList_root,
        bytes32 _skull_root
    ) ERC721A("Indie Skull Syndicate", "$kull") {
        royaltyFeesInBips = _royaltyFeesInBips;
        contractURI = _contractURI;
        whiteList_root = _whiteList_root;
        skull_root = _skull_root;
        royaltyReceiver = msg.sender;
        _safeMint(msg.sender, 1);
    }

    function mint(
        uint256 quantity,
        bytes32[] memory proof,
        bytes32 leaf
    ) external payable {
        // _safeMint's second argument takes in a quantity, not a tokenId.

        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not Enough Tokens Left"
        );

        checkWL = whiteList_MerkleVerify(proof, leaf);
        checkSkull = skullList_MerkleVerify(proof, leaf);

        if (checkSkull == true) {
            amount = skull_List_Mint_Price * quantity;
        } else if (checkWL == true) {
            amount = 0;
        } else {
            amount = mint_Price * quantity;
        }

        if (checkWL == true) {
            if (_numberMinted(msg.sender) >= 1) {
                require(
                    _numberMinted(msg.sender) != 1,
                    "You can only mint 1 NFT"
                );
            }
        } else if (checkSkull == true) {
            if (_numberMinted(msg.sender) >= 2) {
                require(
                    _numberMinted(msg.sender) != 2,
                    "You can only mint 2 NFTs"
                );
            }
        } else {
            if (quantity + _numberMinted(msg.sender) > MAX_MINTS) {
                require(
                    quantity + _numberMinted(msg.sender) < MAX_MINTS,
                    "You can only mint 5 NFTs"
                );
            }
        }

        require(msg.value == amount, "Not Enough Ethers Sent");
        require(block.timestamp >= Skull_List_Time, "Mint Not Yet Started");

        if (checkSkull == true) {
            require(
                Skull_Mints <= 2000,
                "Not Enough Tokens Left for skullList"
            );
            require(block.timestamp < whiteList_Time, "Skull mint ended.");
            // require(quantity == 1, "You can mint only 1 nft");
            _safeMint(msg.sender, quantity);
            Skull_Mints += quantity;
        } else if (checkWL == true) {
            require(WL_Mints <= 500, "Not Enough Tokens Left for OG");
            require(quantity == 1, "You can mint only 1 nft");
            require(block.timestamp < end_of_WL_mint, "WhiteList Mint ended.");
            if (block.timestamp >= whiteList_Time || totalSupply() >= 1001) {
                _safeMint(msg.sender, quantity);
                WL_Mints += quantity;
            } else {
                // require(totalSupply() >= 2031, "OG mint not started yet.");
                require(
                    block.timestamp >= whiteList_Time,
                    "OG Still Have Time To Mint"
                );
            }
        } else {
            if (block.timestamp >= mint_Time || totalSupply() >= 1501) {
                _safeMint(msg.sender, quantity);
                Public_Mints += quantity;
            } else {
                require(
                    block.timestamp >= mint_Time,
                    "Public Mint not yet Started"
                );
            }
        }
    }

    function whiteList_MerkleVerify(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whiteList_root, leaf);
    }

    function skullList_MerkleVerify(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, skull_root, leaf);
    }

    function add_WhiteList_Hash(bytes32 _root) public onlyOwner {
        whiteList_root = _root;
    }

    function add_skullList_Hash(bytes32 _root) public onlyOwner {
        skull_root = _root;
    }

    function changePrices(uint256 _mintPrice, uint256 _skullListPrice)
        public
        onlyOwner
    {
        mint_Price = _mintPrice;
        skull_List_Mint_Price = _skullListPrice;
    }

    function ChangeOwner(address _OwnerAddress) public onlyOwner {
        OwnerAddress = _OwnerAddress;
    }

    function withdraw() external payable onlyOwner {
        //Developer's stake
        uint256 ds = (address(this).balance * 15) / 100;
        // uint256 collab = (address(this).balance * 15) / 100;
        payable(DeveloperAddress).transfer(ds);
        // payable(collabAddress).transfer(collab);

        //Owner's stake
        payable(OwnerAddress).transfer(address(this).balance);
    }

    function setTimer(
        uint32 _stamp,
        uint32 _Skull_List_Time,
        uint32 _wl,
        uint32 _end_of_WL_mint
    ) public onlyOwner {
        mint_Time = _stamp;
        Skull_List_Time = _Skull_List_Time;
        whiteList_Time = _wl;
        end_of_WL_mint = _end_of_WL_mint;
    }

    ////////////////////////////////
    // Royalty functionality
    ///////////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256, /*_tokenId */
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return (royaltyReceiver, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        royaltyReceiver = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function setContractUri(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setRootHashes(bytes32 _whiteList_root, bytes32 _skull_root)
        public
        onlyOwner
    {
        whiteList_root = _whiteList_root;
        skull_root = _skull_root;
    }

    ///////////////////////////////////////////

    function setStakeAddress(address _developer) public onlyOwner {
        DeveloperAddress = _developer;
        // PartnerAddress = _partner;
    }

    // function setCollabAddress(address _collab) public onlyOwner {
    //     collabAddress = _collab;
    // }

    function suppliedNFTs() public view returns (uint256) {
        return totalSupply();
    }

    function userMint() public view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
}
