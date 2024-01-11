// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./ERC1155Supply.sol";
import "./IDropperToken.sol";

contract DropperToken is IDropperToken, ERC1155, AccessControl, ERC1155Supply {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event RewardClaimed(address indexed owner, uint256 indexed id, uint256 reward);
    event TokensClaimed(address indexed owner, uint256 indexed id, uint256 amount);

    struct OwnerRewardInfo {
        uint96 updatedAtReward;
        uint40 mintableBalance;
        uint120 rewardBalance;
    }

    string private _contractUri;
    mapping(address => mapping(uint256 => bool)) private _addressToMintedForToken;
    mapping(uint256 => mapping(address => OwnerRewardInfo)) private _ownerRewardInfo;
    mapping(uint256 => uint256) private _rewardPerShare;
    mapping(uint256 => uint256) private _totalMintableSupply;

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setURI(string memory newUri) external onlyRole(URI_SETTER_ROLE) {
        _setURI(newUri);
    }

    function setContractURI(string memory contractUri) external onlyRole(URI_SETTER_ROLE) {
        _setContractURI(contractUri);
    }

    function tryAddMintable(
        address[] memory to,
        uint256[] memory amounts,
        address tokenAddress,
        uint256 tokenId)
        external
        onlyRole(MINTER_ROLE)
    {
        bool isMinted = _addressToMintedForToken[tokenAddress][tokenId];
        if (isMinted == true) {
            return;
        }

        _addressToMintedForToken[tokenAddress][tokenId] = true;
        _addMintableTokens(to, amounts, tokenAddress, 1);
    }

    function tryAddMintableBatch(
        address[] memory to,
        uint256[] memory amounts,
        address tokenAddress,
        uint256[] memory tokenIds)
        external
        onlyRole(MINTER_ROLE)
    {
        uint256 count;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            bool isMinted = _addressToMintedForToken[tokenAddress][tokenIds[i]];
            if (isMinted == false) {
                _addressToMintedForToken[tokenAddress][tokenIds[i]] = true;
                count++;
            }
        }

        if (count == 0) {
            return;
        }

        _addMintableTokens(to, amounts, tokenAddress, count);
    }

    function addReward(address tokenAddress) external payable { 
        require(msg.value > 0, "DropperToken: reward cannot be 0");

        uint256 id = _getId(tokenAddress);
        uint256 totalSupplyValue = totalSupply(id) + _totalMintableSupply[id];
        require(totalSupplyValue > 0, "DropperToken: no reward recipients");

        _rewardPerShare[id] += msg.value / totalSupplyValue;
    }

    function claimReward(uint256 id) external {
        OwnerRewardInfo storage info = _ownerRewardInfo[id][msg.sender];
        _updateOwnerReward(info, msg.sender, id);

        uint256 rewardBalance = info.rewardBalance;
        require(rewardBalance > 0, "DropperToken: nothing to claim");

        info.rewardBalance = 0;

        payable(msg.sender).transfer(rewardBalance);
        emit RewardClaimed(msg.sender, id, rewardBalance);
    }

    function claimRewardBatch(uint256[] calldata ids) external {
        uint256 total = 0;
        for(uint256 i = 0; i < ids.length; i++) {
            OwnerRewardInfo storage info = _ownerRewardInfo[ids[i]][msg.sender];
            _updateOwnerReward(info, msg.sender, ids[i]);

            uint256 rewardBalance = info.rewardBalance;
            if (rewardBalance > 0) {
                info.rewardBalance = 0;
                total = total + rewardBalance;
                emit RewardClaimed(msg.sender, ids[i], rewardBalance);
            }
        }

        require(total > 0, "DropperToken: nothing to claim");
        payable(msg.sender).transfer(total);
    }

    function claimTokens(uint256 id) external {
        _claimTokens(id);
    }

    function claimTokensBatch(uint256[] calldata ids) external {
        for(uint256 i = 0; i < ids.length; i++) {
            _claimTokens(ids[i]);
        }
    }

    function rewardBalanceOf(address owner, uint256 id) external view returns (uint256) {
        return _rewardBalanceOf(owner, id);
    }

    function rewardBalanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory) {
        require(owners.length == ids.length, "DropperToken: owners and ids length mismatch");

        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = _rewardBalanceOf(owners[i], ids[i]);
        }

        return balances;
    }

    function mintableBalanceOf(address owner, uint256 id) external view returns (uint256) {
        return _mintableBalanceOf(owner, id);
    }

    function mintableBalanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory) {
        require(owners.length == ids.length, "DropperToken: owners and ids length mismatch");

        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = _mintableBalanceOf(owners[i], ids[i]);
        }

        return balances;
    }

    function isMintedForToken(address tokenAddress, uint256 tokenId) external view returns (bool) {
        return _isMintedForToken(tokenAddress, tokenId);
    }

    function isMintedForTokenBatch(address[] calldata tokenAddresses, uint256[] calldata tokenIds) external view returns (bool[] memory) {
        require(tokenAddresses.length == tokenIds.length, "DropperToken: tokenAddresses and tokenIds length mismatch");

        bool[] memory isMinted = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isMinted[i] = _isMintedForToken(tokenAddresses[i], tokenIds[i]);
        }

        return isMinted;
    }

    function totalMintableSupply(uint256 id) external view returns (uint256) {
        return _totalMintableSupply[id];
    }

    function totalMintableSupplyBatch(uint256[] calldata ids) external view returns (uint256[] memory) {
        uint256[] memory supply = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            supply[i] = _totalMintableSupply[ids[i]];
        }

        return supply;
    }

    function totalSupplyBatch(uint256[] calldata ids) external view returns (uint256[] memory) {
        uint256[] memory supply = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            supply[i] = totalSupply(ids[i]);
        }

        return supply;
    }

    function getAddress(uint256 id) external pure returns (address) {
        return _getAddress(id);
    }

    function getAddressBatch(uint256[] calldata ids) external pure returns (address[] memory) {
        address[] memory addresses = new address[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            addresses[i] = _getAddress(ids[i]);
        }

        return addresses;
    }

    function getId(address tokenAddress) external pure returns (uint256) {
        return _getId(tokenAddress);
    }

    function getIdBatch(address[] calldata tokenAddresses) external pure returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            ids[i] = _getId(tokenAddresses[i]);
        }

        return ids;
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function uri(uint256 id) public view override(ERC1155) returns (string memory) { 
        return string(bytes.concat(bytes(super.uri(id)), bytes(Strings.toString(id))));
    }

    function _setContractURI(string memory contractUri) internal {
        _contractUri = contractUri;
    }

    function _addMintableTokens(
        address[] memory to,
        uint256[] memory amounts,
        address tokenAddress,
        uint256 count)
        internal
    {
        uint256 addedSupply;
        uint256 id = _getId(tokenAddress);
        for (uint256 i = 0; i < to.length; i++) {
            OwnerRewardInfo storage info = _ownerRewardInfo[id][to[i]];
            _updateOwnerReward(info, to[i], id);
            uint40 addAmount = uint40(amounts[i] * count);
            info.mintableBalance += addAmount;
            addedSupply += addAmount;
        }

        _totalMintableSupply[id] += addedSupply;
    }

    function _updateOwnerReward(OwnerRewardInfo storage info, address owner, uint256 id) internal {
        uint256 currentReward = _rewardPerShare[id];
        if (info.updatedAtReward == currentReward) {
            return;
        }

        uint256 newRewardBalance = _calculateRewardBalance(info, owner, id, currentReward);
        if (info.rewardBalance != newRewardBalance) {
            info.rewardBalance = uint120(newRewardBalance);
        }

        info.updatedAtReward = uint96(currentReward);
    }

    function _claimTokens(uint256 id) internal {
        OwnerRewardInfo storage info = _ownerRewardInfo[id][msg.sender];
        _updateOwnerReward(info, msg.sender, id);

        uint256 mintableBalance = info.mintableBalance;
        require(mintableBalance > 0, "DropperToken: nothing to claim");

        info.mintableBalance = 0;
        _totalMintableSupply[id] -= mintableBalance;

        _mint(msg.sender, id, mintableBalance, "");
        emit TokensClaimed(msg.sender, id, mintableBalance);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _updateOwnerReward(_ownerRewardInfo[ids[i]][from], from, ids[i]);
            }
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            _updateOwnerReward(_ownerRewardInfo[ids[i]][to], to, ids[i]);
        }
    }

    function _rewardBalanceOf(address owner, uint256 id) internal view returns (uint256) {
        OwnerRewardInfo memory info = _ownerRewardInfo[id][owner];
        return _calculateRewardBalance(info, owner, id, _rewardPerShare[id]);
    }

    function _calculateRewardBalance(OwnerRewardInfo memory info, address owner, uint256 id, uint256 currentReward) internal view returns (uint256) {
        uint256 balance = balanceOf(owner, id) + info.mintableBalance;
        if (balance != 0) {
            uint256 userReward = balance * (currentReward - info.updatedAtReward);
            return info.rewardBalance + userReward;
        }

        return info.rewardBalance;
    }

    function _mintableBalanceOf(address owner, uint256 id) internal view returns (uint256) {
        return _ownerRewardInfo[id][owner].mintableBalance;
    }

    function _isMintedForToken(address tokenAddress, uint256 tokenId) internal view returns (bool) {
        return _addressToMintedForToken[tokenAddress][tokenId];
    }

    function _getId(address tokenAddress) internal pure returns (uint256) {
        return uint256(uint160(tokenAddress));
    }

    function _getAddress(uint256 id) internal pure returns (address) {
        return address(uint160(id));
    }
}
