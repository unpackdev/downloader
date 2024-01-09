// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

// royalties standard
import "./ERC2981ContractWideRoyalties.sol"; 

import "./IMBytes.sol";
import "./IMoonChipsRewards.sol";

import "./EncodingUtils.sol";
import "./StringUtils.sol";

struct GenesisDigitPath {
    uint256 tokenId;
    string svgPath;
}

struct TemplatePath {
    string colorIdx;
    string svgPath;
}

contract MoonChipsERC1155 is ERC1155, Ownable, ERC2981ContractWideRoyalties {

    using SafeMath for uint256;

    address mbytesAddress;
    address rewardsAddress;

    address royaltyRecipient;

    TemplatePath[] templatePaths;

    // map of Gen. Chip # to SVG Pixels
    mapping(uint256 => string) public genesisDigitVectors;
    // color palettes for each chip collection
    mapping(uint8 => string[]) public palettes;
    // supplies for each chip collection
    mapping(uint8 => uint256) public collectionCounts;

    uint256 constant GENESIS_MAX_TOKEN_ID = 88;
    uint256 constant BETA_MAX_TOKEN_ID = 444;
    uint256 constant T_MAX_TOKEN_ID = 4444;

    event WithdrawFunds(address _to, uint256 _amount);
    event ChipsMinted(address _to, uint256 _amount, uint256[] _tokenIds);

    constructor(address _mbytesAddress, address _royaltyRecipient) ERC1155("") {

        mbytesAddress = _mbytesAddress;
        royaltyRecipient = _royaltyRecipient;

        collectionCounts[1] = 0;
        collectionCounts[2] = 0;
        collectionCounts[3] = 0;

        // 8% royalties on all tokens
        _setRoyalties(royaltyRecipient, 800); 
    }
 
    /**
     * @dev batch mint
     * @param _collectionId which chip collection to mint
     * @param _amount amount of chips to mint
     * 0.1 ether / chip
     */
    function mintChips(uint8 _collectionId, uint256 _amount)
        public
        payable
    {
        require(_amount <= 8, "can only mint a maximum of 8 chips at a time");
        require(_collectionId > 0 && _collectionId <= 3, "invalid collection id");
        require(msg.value >= _amount.mul(100000000 gwei), "insufficient funds, 0.1 ether per chip needed");

        mintInternal(msg.sender, _collectionId, _amount);
    }

    function mintInternal(address _address, uint8 _collectionId, uint256 _amount)
        internal
    {
        require(rewardsAddress != address(0x0), "rewards address not set");

        uint256 collectionCount = collectionCounts[_collectionId];

        require(
            collectionCount.add(_amount) <= resolveMaxTokenId(_collectionId),
            "collection supply limit reached"
        );

        if (_collectionId > 1) {
            require(
                collectionFull(_collectionId - 1),
                "previous collection must be fully minted before minting this collection"
            );
        } else {
            // genesis collection is reserved for migrations
            require(
                msg.sender == owner(),
                "only owner can mint genesis collection"
            );
        }

        uint[] memory idsToMint = new uint[](_amount);
        uint[] memory amountsToMint = new uint[](_amount);

        for (uint256 i = 1; i <= _amount; i++) { 

            uint256 amountToAdd = 0;
            if (_collectionId > 1) {
                amountToAdd = amountToAdd.add(resolveMaxTokenId(_collectionId - 1));
            }

            uint256 tokenId = collectionCount.add(amountToAdd.add(i));

            idsToMint[i - 1] = tokenId;
            amountsToMint[i - 1] = 1;
            IMoonChipsRewards(rewardsAddress).updateBlockCount(tokenId, block.number);
        }

        _mintBatch(_address, idsToMint, amountsToMint, '');
        collectionCounts[_collectionId] = collectionCount.add(_amount);

        emit ChipsMinted(_address, _amount, idsToMint);
        
    }


    /**
     * @dev Return the On-Chain SVG Artwork for a given Chip #
     * @param _tokenId The trait type index
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId > 0 && _tokenId <= T_MAX_TOKEN_ID, "token is invalid");

        uint8 collectionId = resolveCollectionId(_tokenId);

        string memory collectionName;
        string memory baseReward;
        string memory description;
        string memory tokenIdStr = StringUtils.toString(_tokenId);


        if (collectionId == 1) {
            collectionName = 'Genesis';
            baseReward = '0.8 MBYTE';
            description = 'The first chip ever developed by Moon Chip Co., fully on-chain, making blockchains STRONGER.';
        } else if (collectionId == 2) {
            collectionName = 'Beta';
            baseReward = '0.4 MBYTE';
            description = 'On-Chain NFT, making blockchains STRONGER';
        } else if (collectionId == 3) {
            collectionName = 'T';
            baseReward = '0.2 MBYTE';
            description = 'On-Chain NFT, making blockchains STRONGER';
        }

        // Hack to get around the fact that we can't have a tokenId of zero
        // TokenID 66 will effectively be TokenID 00
        if (_tokenId == 66) {
            tokenIdStr = '00'; 
        }

        string memory tokenName = string (
            abi.encodePacked(
                collectionName,
                ' #',
                tokenIdStr
            )
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                EncodingUtils.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name":"', tokenName,
                                '", "description":"', description,
                                '", "image": "data:image/svg+xml;base64,',
                                EncodingUtils.encode(
                                    bytes(generateSvg(_tokenId, collectionId))
                                ),
                                '","properties": {"baseReward": "', baseReward,
                                '"}}'
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev OpenSea Collection metadata gen
     */
    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                EncodingUtils.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Moon Chip Co.",',
                                '"description": "NFT Chips that make blockchains STRONGER",',
                                '"image": "https://moonchip.co/wp-content/uploads/2021/09/moonchip.co-logo100x100.png",',
                                '"external_link": "https://moonchip.co",',
                                '"seller_fee_basis_points": 800,',
                                '"fee_recipient": "0x',
                                StringUtils.toAsciiString(royaltyRecipient),
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Generates the SVG Artwork for a given Chip
     * @param _tokenId token id for the chip
     * @param _collectionId collection id for the chip
     */
    function generateSvg(uint256 _tokenId, uint8 _collectionId)
        public
        view
        returns (string memory)
    {
        require(_tokenId > 0); // check that it's a valid token ID
        
        string memory svgVectors = "";

        for(uint8 i = 0; i < templatePaths.length; i++) {

            string memory path = templatePaths[i].svgPath;
            uint8[2] memory substr = [0,0];
            if (_collectionId == 1) {
                substr = [0,2];
            } else if(_collectionId == 2) {
                substr = [2,4];
            } else if(_collectionId == 3) {
                substr = [5,6];
            }
            string memory color = palettes[_collectionId][StringUtils.parseInt(StringUtils.substring(templatePaths[i].colorIdx,substr[0],substr[1]))];

            svgVectors = string(
                abi.encodePacked(
                    svgVectors,
                    '<path d="',
                    path,
                    '" fill="',
                    color,
                    '"/>'
                )
            );
        }
        
        string memory svg = string(
            abi.encodePacked(
                '<?xml version="1.0" standalone="yes"?>',
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">',
                svgVectors
            )
        );

        // Genesis Chip Digit generation
        if (_collectionId == 1) {

            require(
                !StringUtils.isStringEmpty(genesisDigitVectors[_tokenId]),
                'Genesis Digit has not been initialized!'
            );
            
            string[] memory genesisPathArray = StringUtils.split(genesisDigitVectors[_tokenId], ",");
            for (uint8 o = 0; o < genesisPathArray.length; o++) {

                string memory digitColor = '#af01fa';
                string memory digitPath = genesisPathArray[o];


                if (keccak256(bytes(StringUtils.substring(digitPath, 0, 1))) == keccak256(bytes('%'))) {
                    digitColor = '#191818';
                    digitPath = StringUtils.substring(digitPath, 1, bytes(digitPath).length - 1);
                }

                svg = string(
                    abi.encodePacked(
                        svg,
                        '<path d="',
                        digitPath,
                        '" fill="',
                        digitColor,
                        '"/>'
                    )
                );
            }
            
        }

        return string(
            abi.encodePacked(
                svg,
                '</svg>'
            )
        );
    }

    function getOwnedTokens()
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownedTokensCount = 0;

        for (uint256 i = 1; i <= T_MAX_TOKEN_ID; i++) {
            if (balanceOf(msg.sender, i) > 0) {
                ownedTokensCount = ownedTokensCount + 1;
            }
        }

        uint256[] memory ownedTokens = new uint256[](ownedTokensCount);
        uint256 ownedTokenIdx = 0;
        
        for (uint256 i = 1; i <= T_MAX_TOKEN_ID; i++) {
            if (balanceOf(msg.sender, i) > 0) {
                ownedTokens[ownedTokenIdx] = i;
                ownedTokenIdx = ownedTokenIdx + 1;
            }
        }

        return ownedTokens;
    }

    function collectionFull(uint8 _collectionId)
        public
        view
        returns (bool full)
    {
        require(_collectionId > 0 && _collectionId <= 3, "invalid collection id");

        if (_collectionId == 1) {
            full = collectionCounts[_collectionId] >= GENESIS_MAX_TOKEN_ID;
        } else if (_collectionId == 2) {
            full = collectionCounts[_collectionId] >= BETA_MAX_TOKEN_ID;
        } else if (_collectionId == 3) {
            full = collectionCounts[_collectionId] >= T_MAX_TOKEN_ID;
        }
    }

    function resolveCollectionId(uint256 _tokenId)
        internal
        pure
        returns (uint8 collectionId)
    {
        if (_tokenId > 0 && _tokenId <= GENESIS_MAX_TOKEN_ID) {
            collectionId = 1; // genesis
        } else if (_tokenId > GENESIS_MAX_TOKEN_ID && _tokenId <= BETA_MAX_TOKEN_ID) {
            collectionId = 2; // beta
        } else if (_tokenId > BETA_MAX_TOKEN_ID && _tokenId <= T_MAX_TOKEN_ID) { 
            collectionId = 3; // T
        }
    }

    function resolveMaxTokenId(uint256 _collectionId)
        internal
        pure
        returns (uint256 maxTokenId)
    {
        if (_collectionId == 1) {
            maxTokenId = GENESIS_MAX_TOKEN_ID;
        } else if (_collectionId == 2) {
            maxTokenId = BETA_MAX_TOKEN_ID;
        } else if (_collectionId == 3) {
            maxTokenId = T_MAX_TOKEN_ID;
        }
    }

     /**
     * @dev mints all genesis chips to the migration address
     * @param _to migration contract address
     */
    function mintAllCollection(address _to, uint8 _collectionId)
        public
        onlyOwner
    {
        uint256 maxTokenId = resolveMaxTokenId(_collectionId);
        mintInternal(_to, _collectionId, maxTokenId);
    }

    /**
     * @dev Sets colors for specific collection palette
     * @param _colors colors
     * @param _collectionId collection id (1, 2, 3)
     */
    function setPaletteColors(uint8 _collectionId, string[] memory _colors)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _colors.length; i++) {
            palettes[_collectionId].push(_colors[i]);
        }
    }

    /**
     * @dev Add a trait type
     * @param _genesisVectors The trait type index
     */
    function setGenesisDigitVectors(GenesisDigitPath[] memory _genesisVectors)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _genesisVectors.length; i++) {
            genesisDigitVectors[_genesisVectors[i].tokenId] = _genesisVectors[i].svgPath;
        }
    }

    /**
     * @dev Sets the genesis template SVG
     * @param _templatePaths The template SVG
     */
    function setTemplateVectors(TemplatePath[] memory _templatePaths)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _templatePaths.length; i++) {
            templatePaths.push(_templatePaths[i]);
        }
    }

    /**
     * @dev Sets the mbytes ERC20 address
     * @param _mbytesAddress The mbytes address
     */
    function setMBytesAddress(address _mbytesAddress) public onlyOwner {
        mbytesAddress = _mbytesAddress;
    }

    /**
     * @dev Sets the moonchip rewards address
     * @param _rewardsAddress The mbytes address
     */
    function setRewardsAddress(address _rewardsAddress) public onlyOwner {
        rewardsAddress = _rewardsAddress;
    }

    /**
     * @dev Sets royalty recipient address
     * @param _royaltyRecipient the royalty recipient address
     */
    function setRoyaltyRecipient(address _royaltyRecipient) public onlyOwner {
        royaltyRecipient = _royaltyRecipient;
         _setRoyalties(royaltyRecipient, 800); 
    }

    function withdrawFunds(address payable _to) 
        public
        onlyOwner
    {
        uint balance = address(this).balance;
        require(balance > 0, "Balance should be > 0.");
        _to.transfer(balance);
        emit WithdrawFunds(_to, balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}