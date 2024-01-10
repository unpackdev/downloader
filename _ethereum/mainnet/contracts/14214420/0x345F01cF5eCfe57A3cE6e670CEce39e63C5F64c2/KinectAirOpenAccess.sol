// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IKinectAirOpenAccess.sol";
import "./Base64.sol";
import "./KinectAirBaseERC721.sol";

/*


      ___                  ___         ___         ___      ___         ___                   ___     
     /\__\       ___      /\__\       /\  \       /\  \    /\  \       /\  \        ___      /\  \    
    /:/  /      /\  \    /::|  |     /::\  \     /::\  \   \:\  \     /::\  \      /\  \    /::\  \   
   /:/__/       \:\  \  /:|:|  |    /:/\:\  \   /:/\:\  \   \:\  \   /:/\:\  \     \:\  \  /:/\:\  \  
  /::\__\____   /::\__\/:/|:|  |__ /::\~\:\  \ /:/  \:\  \  /::\  \ /::\~\:\  \    /::\__\/::\~\:\  \ 
 /:/\:::::\____/:/\/__/:/ |:| /\__/:/\:\ \:\__/:/__/ \:\__\/:/\:\__/:/\:\ \:\__\__/:/\/__/:/\:\ \:\__\
 \/_|:|~~|~ /\/:/  /  \/__|:|/:/  \:\~\:\ \/__\:\  \  \/__/:/  \/__\/__\:\/:/  /\/:/  /  \/_|::\/:/  /
    |:|  |  \::/__/       |:/:/  / \:\ \:\__\  \:\  \    /:/  /         \::/  /\::/__/      |:|::/  / 
    |:|  |   \:\__\       |::/  /   \:\ \/__/   \:\  \   \/__/          /:/  /  \:\__\      |:|\/__/  
    |:|  |    \/__/       /:/  /     \:\__\      \:\__\                /:/  /    \/__/      |:|  |    
     \|__|                \/__/       \/__/       \/__/                \/__/                 \|__|    


*/

contract KinectAirOpenAccess is IKinectAirOpenAccess, KinectAirBaseERC721 {
    using Strings for uint256;
    using Strings for uint8;

    uint16 private _royalty;
    address private _royaltyAddress;
    mapping(Tier => TierData) public getTier;
    mapping(uint256 => TokenData) public getToken;

    string private _imageBaseURI;

    constructor(
        string memory name,
        string memory symbol,
        uint8 reserved,
        string memory imageBaseURI,
        address[] memory minters,
        address[] memory recipients,
        uint16[] memory splits,
        address royaltyAddress,
        uint16 royaltyAmount
    ) KinectAirBaseERC721(name, symbol, reserved) SplitWithdrawable(recipients, splits) {
        // token

        _imageBaseURI = imageBaseURI;
        _royaltyAddress = royaltyAddress;
        _royalty = royaltyAmount;

        // tiers

        getTier[Tier.FIRST_ACCESS].name = 'First Access';
        getTier[Tier.PRIORITY_ACCESS].name = 'Priority Access';
        getTier[Tier.ADVANCED_ACCESS].name = 'Advanced Access';

        getTier[Tier.FIRST_ACCESS].price = 3 ether;
        getTier[Tier.PRIORITY_ACCESS].price = 0.5 ether;
        getTier[Tier.ADVANCED_ACCESS].price = 0.05 ether;

        getTier[Tier.FIRST_ACCESS].max_supply = 15;
        getTier[Tier.PRIORITY_ACCESS].max_supply = 500;
        getTier[Tier.ADVANCED_ACCESS].max_supply = 5000;

        // benefits

        getTier[Tier.FIRST_ACCESS].flights_free = 1;
        getTier[Tier.FIRST_ACCESS].fly_in = 5;
        getTier[Tier.FIRST_ACCESS].art_prints = 1;
        getTier[Tier.FIRST_ACCESS].vote_weight = 8;

        getTier[Tier.PRIORITY_ACCESS].flights_discount = 1;
        getTier[Tier.PRIORITY_ACCESS].vote_weight = 4;
        getTier[Tier.PRIORITY_ACCESS].fly_in = 2;

        getTier[Tier.ADVANCED_ACCESS].vote_weight = 2;

        for (uint256 i = 0; i < minters.length; i++) {
            _setupRole(MINTER_ROLE, minters[i]);
        }
    }

    function mint(Tier[] calldata tiers) public payable {
        // check that the msg.value matches the sum of the price for the tiers
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < tiers.length; i++) {
            totalPrice += getTier[tiers[i]].price;
        }
        require(msg.value == totalPrice, 'KAOA/invalid-value');
        for (uint256 i = 0; i < tiers.length; i++) {
            _mint(_msgSender(), ++tokenIdCounter, tiers[i]);
        }
    }

    /// @dev get the royalty destination and amount for a token sale
    /// @param salePrice the token ID
    /// @return the recipient and aount
    function royaltyInfo(uint256, uint256 salePrice) public view override returns (address, uint256) {
        return (_royaltyAddress, (salePrice * _royalty) / BASE);
    }

    /// TOKEN

    /// @dev get the URI for a token ID metadata
    /// @param tokenId the token ID
    /// @return the URI
    function tokenURI(uint256 tokenId) public view override mustExist(tokenId) returns (string memory) {
        return _getEncodedTokenUri(tokenId);
    }

    /// @dev get the vote weight for a token ID
    /// @param tokenId the token ID
    /// @return the weight
    function tokenVoteWeight(uint256 tokenId) public view returns (uint256) {
        return getToken[tokenId].vote_weight;
    }

    /// @dev get the free flights for a token ID
    /// @param tokenId the token ID
    /// @return the flights
    function tokenFlightsFree(uint256 tokenId) public view returns (uint8) {
        return getToken[tokenId].flights_free;
    }

    /// @dev get the discounted flights for a token ID
    /// @param tokenId the token ID
    /// @return the flights
    function tokenFlightsDiscount(uint256 tokenId) public view returns (uint8) {
        return getToken[tokenId].flights_discount;
    }

    /// @dev get the fly-in entry for a token ID
    /// @param tokenId the token ID
    /// @return the entry count
    function tokenFlyIn(uint256 tokenId) public view returns (uint8) {
        return getToken[tokenId].fly_in;
    }

    /// @dev get the free art prints for a token ID
    /// @param tokenId the token ID
    /// @return the prints
    function tokenArtPrints(uint256 tokenId) public view returns (uint8) {
        return getToken[tokenId].art_prints;
    }

    /// TIER DATA

    /// @dev get the name for a given tier
    /// @param tier the tier
    /// @return the tier name
    function tierName(Tier tier) public view returns (string memory) {
        return getTier[tier].name;
    }

    /// @dev get the name for a given tier
    /// @param tier the tier
    /// @return the tier price
    function tierPrice(Tier tier) public view returns (uint256) {
        return getTier[tier].price;
    }

    /// @dev get the max supply for a given tier
    /// @param tier the tier
    /// @return the max tier supply
    function tierMaxSupply(Tier tier) public view returns (uint32) {
        return getTier[tier].max_supply;
    }

    /// @dev get the total supply for a given tier
    /// @param tier the tier
    /// @return the total tier supply
    function tierTotalSupply(Tier tier) public view returns (uint32) {
        return getTier[tier].total_supply;
    }

    /// MINTER

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address[] calldata to, Tier[] calldata tier) public onlyMinters {
        require(to.length == tier.length, 'KAOA/invalid-array-length');
        for (uint256 i = 0; i < to.length; i++) {
            require(tier[i] != Tier.NONE, 'KAOA/invalid-tier');
            _mint(to[i], ++tokenIdCounter, tier[i]);
        }
    }

    /// @dev allow minters to bulk mint a specific token ID and tier for a set of recipients
    /// @param to the recipien
    /// @param tokenId the token IDs
    /// @param tier the tiers
    function mint(
        address[] calldata to,
        uint256[] calldata tokenId,
        Tier[] calldata tier
    ) public onlyMinters {
        // check array lengths
        require(to.length == tokenId.length && tokenId.length == tier.length, 'KAOA/invalid-array-length');
        for (uint256 i = 0; i < to.length; i++) {
            require(tier[i] != Tier.NONE, 'KAOA/invalid-tier');
            require(tokenId[i] <= TOKENS_RESERVED, 'KAOA/invalid-token-id');
            _mint(to[i], tokenId[i], tier[i]);
        }
    }

    /// OWNER

    /// @dev set the tier image for a Tier
    /// @param uri the image uri
    function setImageBaseUri(string calldata uri) external onlyOwner {
        emit ImageBaseUpdated(_imageBaseURI, uri);
        _imageBaseURI = uri;
    }

    /// @dev update the data for a tier
    /// @param tier the tier
    /// @param tierData the tier data, including name
    function updateTier(Tier tier, TierData memory tierData) external onlyOwner {
        require(tier != Tier.NONE, 'KAOA/invalid-tier');
        require(tierData.max_supply >= getTier[tier].total_supply, 'KAOA/invalid-max-supply');
        // update values, except supply
        tierData.total_supply = getTier[tier].total_supply;
        _updateTier(tier, tierData);
    }

    /// @dev update the royalty address
    /// @param _reciever the royalty reciever
    function setRoyaltyAddress(address _reciever) external onlyOwner {
        require(_reciever != address(0), 'KAOA/invalid-reciever');
        emit RoyaltyAddressUpdated(_royaltyAddress, _reciever);
        _royaltyAddress = _reciever;
    }

    /// @dev set the royalty amount
    /// @param amount the amount
    function setRoyalty(uint16 amount) external onlyOwner {
        require(amount < BASE, 'KAOA/invalid-royalty');
        emit RoyaltyAmountUpdated(_royalty, amount);
        _royalty = amount;
    }

    /// OPERATOR

    /// @dev allow the operator role to update the token data all at once
    /// @param tokenId the token id
    /// @param tokenData the token data
    function updateTokenData(uint256 tokenId, TokenData calldata tokenData) external onlyOperators mustExist(tokenId) {
        require(Tier.NONE != tokenData.tier, 'KAOA/invalid-tier');
        // handle supply changes
        if (getToken[tokenId].tier != tokenData.tier) {
            TierData memory oldData = getTier[getToken[tokenId].tier];
            oldData.total_supply -= 1;
            _updateTier(getToken[tokenId].tier, oldData);

            TierData memory newData = getTier[tokenData.tier];
            newData.total_supply += 1;
            _updateTier(tokenData.tier, newData);
        }
        // update the token data
        emit TokenDataUpdated(tokenId, getToken[tokenId], tokenData);
        getToken[tokenId] = tokenData;
    }

    /// INTERNAL

    /// @dev mint a new token ID for a given tier, checks supply per tier.
    /// @param to the recipient
    /// @param tokenId the token ID
    /// @param tier the tier
    function _mint(
        address to,
        uint256 tokenId,
        Tier tier
    ) internal {
        // check total_supply count for this tier
        require(getTier[tier].total_supply < getTier[tier].max_supply, 'KAOA/max-total-supply');
        // increment the mint count
        getTier[tier].total_supply += 1;

        // set token data from tier defaults
        getToken[tokenId].tier = tier;
        getToken[tokenId].flights_free = getTier[tier].flights_free;
        getToken[tokenId].flights_discount = getTier[tier].flights_discount;
        getToken[tokenId].art_prints = getTier[tier].art_prints;
        getToken[tokenId].fly_in = getTier[tier].fly_in;
        getToken[tokenId].vote_weight = getTier[tier].vote_weight;

        super._mint(to, tokenId);
    }

    /// @dev update the data for a tier
    /// @param tier the tier
    /// @param tierData the tier data, including name
    function _updateTier(Tier tier, TierData memory tierData) internal {
        // emit event about change
        emit TierUpdated(tier, getTier[tier], tierData);
        // update the tier
        getTier[tier] = tierData;
    }

    /// @dev generate on chain metadata and image for this id
    /// @param tokenId the token id
    function _getEncodedTokenUri(uint256 tokenId) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{',
                            _getNameJSON(tokenId),
                            ',',
                            _getAttributesJSON(tokenId),
                            ',',
                            _getImageJSON(tokenId),
                            '}'
                        )
                    )
                )
            );
    }

    function _getNameJSON(uint256 tokenId) private view returns (bytes memory) {
        return abi.encodePacked('"name":"', name(), ' #', tokenId.toString(), '"');
    }

    function _getAttributesJSON(uint256 tokenId) private view returns (bytes memory) {
        bytes memory _traits = abi.encodePacked(
            _getAttributeTierJSON(tokenId),
            ',',
            _getAttributeFlightsFreeJSON(tokenId),
            ',',
            _getAttributeFlightsDiscountedJSON(tokenId),
            ',',
            _getAttributeFlyInJSON(tokenId),
            ',',
            _getAttributeArtPrintsJSON(tokenId),
            ',',
            _getAttributeVoteJSON(tokenId)
        );
        return abi.encodePacked('"attributes":[', _traits, ']');
    }

    function _getAttributeTierJSON(uint256 tokenId) private view returns (bytes memory) {
        bytes memory _trait = abi.encodePacked(
            '{"trait_type":"Tier", "value":"',
            getTier[getToken[tokenId].tier].name,
            '"}'
        );
        return _trait;
    }

    function _getAttributeFlightsFreeJSON(uint256 tokenId) private view returns (bytes memory) {
        bytes memory _trait = abi.encodePacked(
            '{"trait_type":"Free Flights", "value":',
            getToken[tokenId].flights_free.toString(),
            '}'
        );
        return _trait;
    }

    function _getAttributeFlightsDiscountedJSON(uint256 tokenId) private view returns (bytes memory) {
        bytes memory _trait = abi.encodePacked(
            '{"trait_type":"Discounted Flights", "value":',
            getToken[tokenId].flights_discount.toString(),
            '}'
        );
        return _trait;
    }

    function _getAttributeArtPrintsJSON(uint256 tokenId) private view returns (bytes memory) {
        bytes memory _trait = abi.encodePacked(
            '{"trait_type":"Art Prints", "value":',
            getToken[tokenId].art_prints.toString(),
            '}'
        );
        return _trait;
    }

    function _getAttributeFlyInJSON(uint256 tokenId) private view returns (bytes memory) {
        bytes memory _trait = abi.encodePacked(
            '{"trait_type":"Fly-In", "value":',
            getToken[tokenId].fly_in.toString(),
            '}'
        );
        return _trait;
    }

    function _getAttributeVoteJSON(uint256 tokenId) private view returns (bytes memory) {
        bytes memory _trait = abi.encodePacked(
            '{"trait_type":"Vote Weight", "value":"',
            getToken[tokenId].vote_weight.toString(),
            '"}'
        );
        return _trait;
    }

    function _getImageJSON(uint256 tokenId) private view returns (bytes memory) {
        Tier _tier = getToken[tokenId].tier;
        return
            abi.encodePacked(
                '"image":"',
                _imageBaseURI,
                _tier == Tier.FIRST_ACCESS ? 'First' : (_tier == Tier.PRIORITY_ACCESS ? 'Priority' : 'Advanced'),
                'Access.gif"'
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // emit event to let us track tier supply
        emit TransferOpenAccess(from, to, tokenId, getToken[tokenId].tier);
    }

    receive() external payable {}
}
