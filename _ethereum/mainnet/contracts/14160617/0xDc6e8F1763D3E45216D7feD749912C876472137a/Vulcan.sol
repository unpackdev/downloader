//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

/*``````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
`````````````````.//////////////////+++++++++++++++.`````````.``````````````````
`````````````````.vulcanvulcanvulcanvulcanvulcanvul-``````.:+c-`````````````````
`````````````````.anvulcanvulcanvulcanvulcanvulcanv-````-ulcan-`````````````````
``````````````````/vulc:`````````````````````/anvul-````/canvu-`````````````````
```````````````````-+lc:`````````````````````/anvul-````/canvu-`````````````````
`````````````````````-l:````.//++++/.````````/canvu-````:lcanv-`````````````````
````````````````````````````.ulcanvul+.``````/canvu-````:lcanv-`````````````````
`````````````````.u:````````.ulcanvulca:`````/nvulc-````:anvul-`````````````````
`````````````````.can:``````.vulcan-````````-vulcan-````:vulca-`````````````````
`````````````````.nvulc:`````-anvulc+.````.anvulca/````.nvulca-`````````````````
``````````````````/nvulca:`````:nvulca+..+nvulca/`````/nvulca+``````````````````
```````````````````./nvulca:`````:nvulcanvulca/.````:nvulca+.```````````````````
`````````````````````./nvulca:`````:nvulcanv/.````:ulcanv+.`````````````````````
```````````````````````./ulcanv:`````/ulca+.````:nvulcan-```````````````````````
`````````````````````````-+vulcan:````./+.````-vulcanv-`````````````````````````
```````````````````````````-ulcanvu:````````-lcanvul-```````````````````````````
`````````````````````````````:canvulc-`````-anvulc:`````````````````````````````
```````````````````````````````:anvulca-````.:nv:.``````````````````````````````
`````````````````````````````````:ulcanvu:````..````````````````````````````````
``````````````````````````````````.:lcanvul-````````````````````````````````````
````````````````````````````````````./canvu.````````````````````````````````````
``````````````````````````````````````.+l-``````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
````````````````````````````````````````````````````````````````````````````````
``````````````````````````````````````````````````````````````````````````````*/

/**
 * @title A tokenization of the Vulcan Authentication service
 * @author Bitquence <@_bitquence> for Vulcan Authentication <@VulcanAuth>
 * @notice A permissioned ERC1155 tiered token
 *
 * The contract owner can mint tokens without payment and burn any current holder's token
 * Token holders can burn their current token and pay ether to upgrade to a higher tier
 * Token holders can transfer their token but cannot set approvals for it
 */
contract Vulcan is ERC1155, Ownable {
    /**
     * @notice Emitted when an owner upgrades their token
     * @param owner The owner of the token which is being upgraded
     * @param oldTier The token's tier before the upgrade
     * @param newTier The token's tier after the upgrade
     */
    event Upgrade(address owner, uint256 oldTier, uint256 newTier);

    /**
     * @notice Emitted when a user buys a new token
     * @dev This event is not emitted if `mint` is called by the owner, instead the event `OwnerMint` is emitted
     * @param owner The owner of the newly minted token
     * @param tier The newly minted token's tier
     */
    event Purchase(address owner, uint256 tier);

    /**
     * @notice Emitted when the owner of this contract purges a user's token
     * @param previousOwner The owner of the token pre-purge
     * @param tier The purged token's tier
     */
    event Purge(address previousOwner, uint256 tier);

    /**
     * @notice Emitted for each token the owner mints by calling the function `mint`
     * @param destination The recipient of the newly minted token
     * @param tier The newly minted token's tier
     */
    event OwnerMint(address destination, uint256 tier);

    /**
     * @notice Emitted when the owner of this contract adds a new tier
     * @param tier ID of the newly added tier
     */
    event TierAdded(uint256 tier);

    struct Tier {
        uint8 id;
        uint248 price;
    }

    mapping(uint256 => Tier) public _tiers;
    mapping(uint256 => bool) private _tierExists;

    string public constant name = "Vulcan";
    string public constant symbol = "VLCN";

    constructor() ERC1155("https://vulcanbot.io/metadata/") {
        _tiers[0] = Tier(0, 0.33 ether);
        _tiers[1] = Tier(1, 1 ether);

        _tierExists[0] = true;
        _tierExists[1] = true;

        _mint(msg.sender, _tiers[0].id, 1, "");
        _mint(msg.sender, _tiers[1].id, 1, "");
    }

    /**
     * @notice Calling this function will cause it to revert
     * @dev Override ERC1155 internal function _setApprovalForAll to disallow users from listing their token on digital marketplaces
     */
    function _setApprovalForAll(
        address,
        address,
        bool
    ) internal virtual override(ERC1155) {
        revert("Vulcan/cannot-approve");
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(super.uri(id), Strings.toString(id), ".json")
            );
    }

    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    /**
     * @notice Mints an ERC-1155 token of tier `tierId` if tier has been defined
     */
    function buy(uint256 _tier) external payable {
        Tier memory tier = _tiers[_tier];

        require(_tierExists[_tier], "Vulcan/tier-not-found");
        require(msg.value >= tier.price, "Vulcan/value-too-low");

        _mint(msg.sender, tier.id, 1, "");

        emit Purchase(msg.sender, tier.id);
    }

    /**
     * @notice Burns a token from the sender of tier `_prev` and mints a token of tier `_next` if sufficient payment is made
     * @dev Prior ownership of token does not have to be checked because it is already done inside the ERC1155 `_burn` function
     */
    function upgradeToTier(uint256 _prev, uint256 _next) external payable {
        Tier memory prev = _tiers[_prev];
        Tier memory next = _tiers[_next];

        require(
            _tierExists[_prev] && _tierExists[_next],
            "Vulcan/tiers-not-found"
        );
        require(msg.value >= (next.price - prev.price), "Vulcan/value-too-low");
        require(prev.id < next.id, "Vulcan/cannot-downgrade");

        _burn(msg.sender, prev.id, 1);
        _mint(msg.sender, next.id, 1, "");

        emit Upgrade(msg.sender, prev.id, next.id);
    }

    /**
     * @notice Burns token of tier `_tier` owned by account `to`
     * @dev Prior ownership of token does not have to be checked because it is already done inside the ERC1155 `_burn` function
     */
    function purgeToken(
        address to,
        uint256 amt,
        uint256 _tier
    ) external onlyOwner {
        Tier memory tier = _tiers[_tier];

        _burn(to, tier.id, amt);

        emit Purge(to, tier.id);
    }

    /**
     * @notice Mints 1 token to each address in array `to` of tier in the array `ids` at the same position
     */
    function mint(address[] calldata to, uint256[] calldata ids)
        external
        onlyOwner
    {
        for (uint256 i; i < to.length; i++) {
            uint256 tier = ids[i];
            address receiver = to[i];

            require(_tierExists[tier], "Vulcan/tier-not-found");

            _mint(receiver, tier, 1, "");

            emit OwnerMint(receiver, tier);
        }
    }

    function addTier(Tier memory tier) external onlyOwner {
        require(!_tierExists[tier.id], "Vulcan/tier-already-exists");

        _tiers[tier.id] = tier;
        _tierExists[tier.id] = true;

        _mint(msg.sender, tier.id, 1, "");

        emit TierAdded(tier.id);
    }

    function withdraw(address payable to, uint256 amt) external onlyOwner {
        to.transfer(amt);
    }
}
