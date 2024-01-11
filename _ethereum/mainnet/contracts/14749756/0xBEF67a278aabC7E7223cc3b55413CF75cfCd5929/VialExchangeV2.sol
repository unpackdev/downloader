//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UpgradeableBase.sol";
import "./AddressUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC165Upgradeable.sol";

contract VialExchangeV2 is
    UpgradeableBase,
    IERC1155ReceiverUpgradeable,
    ERC165Upgradeable,
    PausableUpgradeable
{
    address public constant DEAD_ADDRESS = address(0xdead);    

    IERC1155Upgradeable public vial;
    uint256 public vialTokenId;
    IERC1155Upgradeable[] public rewardTokens;
    uint256[] public rewardTokenIds;
    uint256[] public timestampStartClaims;
    uint256[] public claimDurations;
    uint256[] public rewardQuantities;  //remaining rewards quantities
    uint256[] public rewardTotalQuantities;

    event VialUpdated(address vial, uint256 vialTokenId, address executor);
    event Exchange(address user, address vial, uint256 vialTokenId, uint256 vialAmount, address rewardToken, uint256 rewardTokenId);
    event RewardTokenlUpdated(
        bytes rewardTokens,
        bytes rewardTokenIds,
        bytes rewardQuantities,
        bytes timestampStartClaims,
        bytes claimDurations,
        address executor
    );
    event AddMoreReward(
        address rewardToken, 
        uint256 rewardTokenId, 
        uint256 quantity, 
        uint256 startClaim, 
        uint256 duration
    );
    event UpdateRewardClaimTime(
        uint256 _index, 
        uint256 _start, 
        uint256 _duration);
    event UpdateRewardQuantities(
        uint256 _index, 
        uint256 _newQuantity);
    event StopExchange();

    //after upgrade 5/10/22
    uint256 public maxExchange;

    function initialize(
        IERC1155Upgradeable _vial,
        uint256 _vialTokenId,
        IERC1155Upgradeable[] memory _rewardTokens,
        uint256[] memory _rewardTokenIds,
        uint256[] memory _rewardQuantities,
        uint256[] memory _timestampStartClaims,
        uint256[] memory _claimDurations
    ) external initializer {
        initOwner();
        vial = _vial;
        vialTokenId = _vialTokenId;
        _changeRewardToken(
            _rewardTokens,
            _rewardTokenIds,
            _rewardQuantities,
            _timestampStartClaims,
            _claimDurations
        );
    }

    function changeVial(IERC1155Upgradeable _vial, uint256 _vialTokenId)
        external
        onlyOwner
    {   
        require((address(vial) != address(_vial) || vialTokenId != _vialTokenId), "Already be vial");
        vial = _vial;
        vialTokenId = _vialTokenId;
        emit VialUpdated(address(vial), vialTokenId, msg.sender);
    }

    function changeRewardToken(
        IERC1155Upgradeable[] memory _rewardTokens,
        uint256[] memory _rewardTokenIds,
        uint256[] memory _rewardQuantities,
        uint256[] memory _timestampStartClaims,
        uint256[] memory _claimDurations
    ) external onlyOwner {
        _changeRewardToken(
            _rewardTokens,
            _rewardTokenIds,
            _rewardQuantities,
            _timestampStartClaims,
            _claimDurations
        );
    }

    // Change totol Quantity. The input variables _newQuantity means new Reward Total Quantity  
    // required _newQuantity must higher than the already exchanged reward 

    function updateRewardQuantities(uint256 _index, uint256 _newQuantity) external onlyOwner {
        require(_index< rewardQuantities.length, "Wrong input index");
        require((rewardTotalQuantities[_index] - rewardQuantities[_index]) <= _newQuantity, "invalid new quantity");
        rewardQuantities[_index] = _newQuantity - (rewardTotalQuantities[_index] - rewardQuantities[_index]);
        rewardTotalQuantities[_index] = _newQuantity;
        emit UpdateRewardQuantities(_index, _newQuantity);
    }

    function updateRewardClaimTime(uint256 _index, uint256 _start, uint256 _duration) external onlyOwner {
        require(_index< timestampStartClaims.length, "Wrong input index");
        timestampStartClaims[_index] = _start;
        claimDurations[_index] = _duration;
        emit UpdateRewardClaimTime(_index, _start, _duration);
    }

    function addMoreReward(address _rewardToken, uint256 _rewardTokenId, uint256 _quantity, uint256 _startClaim, uint256 _duration) external onlyOwner {
        for(uint256 i = 0; i < rewardTokens.length; i++) {
            if (address(rewardTokens[i]) == _rewardToken && rewardTokenIds[i] == _rewardTokenId) {
                revert("duplicate");
            }
        }
        rewardTokens.push(IERC1155Upgradeable(_rewardToken));
        rewardTokenIds.push(_rewardTokenId);
        rewardQuantities.push(_quantity);
        rewardTotalQuantities.push(_quantity);
        timestampStartClaims.push(_startClaim);
        claimDurations.push(_duration);
        emit AddMoreReward(_rewardToken, _rewardTokenId, _quantity, _startClaim, _duration);
    }

    function _changeRewardToken(
        IERC1155Upgradeable[] memory _rewardTokens,
        uint256[] memory _rewardTokenIds,
        uint256[] memory _rewardQuantities,
        uint256[] memory _timestampStartClaims,
        uint256[] memory _claimDurations
    ) internal {
        require(
            _rewardTokenIds.length == _rewardTokens.length &&
            _rewardTokenIds.length == _rewardQuantities.length &&
                _rewardQuantities.length == _timestampStartClaims.length &&
                _timestampStartClaims.length == _claimDurations.length,
            "invalid input array length"
        );
        rewardTokens = _rewardTokens;
        rewardTokenIds = _rewardTokenIds;
        rewardQuantities = _rewardQuantities;
        rewardTotalQuantities = _rewardQuantities;
        timestampStartClaims = _timestampStartClaims;
        claimDurations = _claimDurations;
        address[] memory addrList = new address[](_rewardTokens.length);
        for(uint256 i = 0; i < _rewardTokens.length; i++) {
            addrList[i] = address(_rewardTokens[i]);
        }
        emit RewardTokenlUpdated(
            abi.encodePacked(addrList),
            abi.encodePacked(rewardTokenIds),
            abi.encodePacked(rewardQuantities),
            abi.encodePacked(timestampStartClaims),
            abi.encodePacked(claimDurations),
            msg.sender
        );
    }

    function pauseExchange() external onlyOwner {
        _pause();
    }

    function resumeExchange() external onlyOwner {
        _unpause();
    }

    function exchange(uint256 _vialAmount, uint256 _rewardIndex, address _rewardToken, uint256 _rewardTokenId) external whenNotPaused {
        require(_rewardIndex < rewardTokens.length, "index out of bound");
        require(address(rewardTokens[_rewardIndex]) == _rewardToken, "invalid reward token address");
        require(rewardTokenIds[_rewardIndex] == _rewardTokenId, "invalid reward token id");

        require(timestampStartClaims[_rewardIndex] != 0, "not start yet");
        require(
            (timestampStartClaims[_rewardIndex] <= block.timestamp) && (
                block.timestamp <=
                (timestampStartClaims[_rewardIndex] + claimDurations[_rewardIndex])),
            "not start yet"
        );

        require(_vialAmount <= maxExchange, "Exceeded Maximum Exchange");
        require(rewardQuantities[_rewardIndex] >= _vialAmount, "rewards drained");
        rewardQuantities[_rewardIndex] = rewardQuantities[_rewardIndex] - _vialAmount;
        vial.safeTransferFrom(
            msg.sender,
            DEAD_ADDRESS,
            vialTokenId,
            _vialAmount,
            ""
        );

        //transfer rewards
        IERC1155Upgradeable _selectedRewardToken = rewardTokens[_rewardIndex];
        _selectedRewardToken.safeTransferFrom(
            address(this),
            msg.sender,
            _rewardTokenId,
            _vialAmount,
            ""
        );
        emit Exchange(msg.sender, address(vial), vialTokenId, _vialAmount, _rewardToken, _rewardTokenId);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId;
    }

    function getRewardTokenIds() external view returns (uint256[] memory) {
        return rewardTokenIds;
    }

    function getRewardTokenIdsBalance()
        external
        view
        returns (address[] memory tokens, uint256[] memory tokenIds, uint256[] memory balances)
    {
        tokenIds = rewardTokenIds;
        balances = new uint256[](rewardTokenIds.length);
        tokens = new address[](rewardTokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            balances[i] = rewardTokens[i].balanceOf(address(this), tokenIds[i]);
            tokens[i] = address(rewardTokens[i]);
        }
    }

    function getRewardTokenIdsQuantities()
        external
        view
        returns (uint256[] memory tokenIds, uint256[] memory quantities)
    {
        tokenIds = rewardTokenIds;
        quantities = rewardQuantities;
    }

    function getRewardInfo()
        external
        view
        returns (
            IERC1155Upgradeable[] memory _rewardTokens,
            uint256[] memory _rewardTokenIds,
            uint256[] memory _remainRewardQuantities,
            uint256[] memory _totalRewardQuantities,
            uint256[] memory _timestampStartClaims,
            uint256[] memory _claimDurations
        )
    {
        return (
            rewardTokens,
            rewardTokenIds,
            rewardQuantities,
            rewardTotalQuantities,
            timestampStartClaims,
            claimDurations
        );
    }

    function updateMaxExchange(uint256 max) public onlyOwner
    {
        maxExchange = max;
    }
}
