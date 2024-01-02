// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./Initializable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./StringsUpgradeable.sol";

interface IDelegationRegistry {
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view returns (uint256);
}

interface IaKEYcalledBEAST {
    function unlock(uint256 cardId, uint256 amount, address adr) external;
}

contract BeastMart is Initializable, ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    struct Reward {
        bool exists;
        bool mint_active;
        bool unlimited;
        string name;
        uint256 id;
        uint256 supply;
        uint256 max;
        uint256 burns;
    }

    mapping(uint256 => Reward) public rewards;
    address public keyAdr;
    string public baseURI;
    string name_;
    string symbol_;

    error RewardSoulboundNoSetApprovalForAll(address operator, bool approved);
    error RewardSoulboundNoIsApprovedForAll(address account, address operator);
    error RewardSoulboundNoSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes data
    );
    error RewardSoulboundNoSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();

        name_ = "BEASTMART";
        symbol_ = "BMART";
        keyAdr = 0xbe86f8d47A20b4461BA1C30d470779115912FF58;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function setURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    // Rewards are Soulbound
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert RewardSoulboundNoSetApprovalForAll(operator, approved);
    }

    function isApprovedForAll( address account, address operator) public pure override returns (bool) {
        revert RewardSoulboundNoIsApprovedForAll(account, operator);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public virtual override {
        revert RewardSoulboundNoSafeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        revert RewardSoulboundNoSafeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function initialiseReward(
        string memory reward_name,
        uint256 id,
        bool mint_active,
        uint256 max,
        uint256 burns,
        bool unlimited
    ) public onlyOwner {
        require(!rewards[id].exists, "Reward has already been created.");

        rewards[id] = Reward({
            id: id,
            name: reward_name,
            supply: 0,
            exists: true,
            mint_active: mint_active,
            max: max,
            burns: burns,
            unlimited: unlimited
        });
    }

    function updateReward(
        string memory reward_name,
        uint256 id,
        bool mint_active,
        uint256 max,
        uint256 burns,
        bool unlimited
    ) public onlyOwner {
        require(rewards[id].exists, "Reward has to exist in order to update.");

        rewards[id].name = reward_name;
        rewards[id].mint_active = mint_active;
        rewards[id].max = max;
        rewards[id].burns = burns;
        rewards[id].unlimited = unlimited;
    }

    function airdrop(address[] memory adrs, uint256[] memory amounts, uint256 rewardId) external onlyOwner {
        require(adrs.length == amounts.length, "Amounts much match addresses");

        uint256 total = 0;

        for (uint256 i = 0; i < adrs.length; i++) {
            total = total + amounts[i];
            _mint(adrs[i], rewardId, amounts[i], "");
        }

        if (!rewards[rewardId].unlimited) {
            require(rewards[rewardId].max >= rewards[rewardId].supply + total, "Not enough supply left of this reward.");
        }

        rewards[rewardId].supply = rewards[rewardId].supply + total;
    }

    function mintNft(uint256 rewardId, uint256 amount, address vault) external {
        require(rewards[rewardId].mint_active, "Reward minting is not currently active.");

        if (!rewards[rewardId].unlimited) {
            require(rewards[rewardId].max >= rewards[rewardId].supply + amount, "Not enough supply left of this reward.");
        }

        uint256 burn_amount = rewards[rewardId].burns * amount;

        if (vault != msg.sender) {
            IDelegationRegistry delegateO = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

            if (!delegateO.checkDelegateForToken(msg.sender, vault, keyAdr, 1)) {
                IDelegationRegistry delegateT = IDelegationRegistry(0x00000000000000447e69651d841bD8D104Bed493);

                require(delegateT.checkDelegateForERC1155(msg.sender, vault, keyAdr, 1, "") >= burn_amount, "Not owner of claim.");
            }
        }

        IaKEYcalledBEAST(keyAdr).unlock(1, burn_amount, vault);

        rewards[rewardId].supply = rewards[rewardId].supply + amount;
        _mint(vault, rewardId, amount, "");
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return rewards[id].supply;
    }

    function uri(
        uint256 _id
    ) override public view returns (string memory) {
        require(rewards[_id].exists, "ERC721Tradable#uri: NONEXISTENT_TOKEN");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, StringsUpgradeable.toString(_id))) : "";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
