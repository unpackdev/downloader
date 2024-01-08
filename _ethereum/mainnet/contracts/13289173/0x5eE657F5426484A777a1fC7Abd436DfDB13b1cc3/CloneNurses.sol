// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./CloneNurseEnumerable.sol";
import "./IERC1271.sol";
import "./ICloneNurses.sol";
import "./IERC2981.sol";

contract CloneNurses is
    Ownable,
    ERC721("MaidCoin Clone Nurses", "CNURSES"),
    CloneNurseEnumerable,
    ERC1155Holder,
    IERC2981,
    ICloneNurses
{
    struct NurseType {
        uint256 partCount;
        uint256 destroyReturn;
        uint256 power;
        uint256 lifetime;
    }

    struct Nurse {
        uint256 nurseType;
        uint256 endBlock;
        uint256 lastClaimedBlock;
    }

    INursePart public immutable override nursePart;
    IMaidCoin public immutable override maidCoin;
    ITheMaster public immutable override theMaster;
    uint256 private immutable theMasterStartBlock;

    mapping(uint256 => uint256) public override supportingRoute;
    mapping(address => uint256) public override supportingTo;
    mapping(uint256 => uint256) public override supportedPower;
    mapping(uint256 => uint256) public override totalRewardsFromSupporters;

    NurseType[] public override nurseTypes;
    Nurse[] public override nurses;

    uint256 private royaltyFee = 25; // out of 1000
    address private royaltyReceiver; // MaidCafe

    constructor(
        INursePart _nursePart,
        IMaidCoin _maidCoin,
        ITheMaster _theMaster,
        address _royaltyReceiver
    ) {
        nursePart = _nursePart;
        maidCoin = _maidCoin;
        theMaster = _theMaster;
        royaltyReceiver = _royaltyReceiver;
        theMasterStartBlock = _theMaster.startBlock();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.maidcoin.org/clonenurses/";
    }

    function totalSupply() public view override(CloneNurseEnumerable, ICloneNurseEnumerable) returns (uint256) {
        return nurses.length;
    }

    function addNurseType(
        uint256[] calldata partCounts,
        uint256[] calldata destroyReturns,
        uint256[] calldata powers,
        uint256[] calldata lifetimes
    ) external onlyOwner returns (uint256[] memory) {
        uint256 startId = nurseTypes.length;
        uint256[] memory nurseType = new uint256[](partCounts.length);
        for (uint256 i = 0; i < partCounts.length; i += 1) {
            require(partCounts[i] > 1, "CloneNurses: Invalid partCount");
            nurseTypes.push(
                NurseType({
                    partCount: partCounts[i],
                    destroyReturn: destroyReturns[i],
                    power: powers[i],
                    lifetime: lifetimes[i]
                })
            );
            nurseType[i] = (startId + i);
        }
        return nurseType;
    }

    function nurseTypeCount() external view override returns (uint256) {
        return nurseTypes.length;
    }

    function assemble(uint256 _nurseType, uint256 _parts) public override {
        NurseType storage nurseType = nurseTypes[_nurseType];
        uint256 _partCount = nurseType.partCount;
        require(_parts >= _partCount, "CloneNurses: Not enough parts");

        nursePart.safeTransferFrom(msg.sender, address(this), _nurseType, _parts, "");
        nursePart.burn(_nurseType, _parts);
        uint256 lifetime = ((nurseType.lifetime * (_parts - 1)) / (_partCount - 1));
        uint256 startblock = block.number > theMasterStartBlock ? block.number : theMasterStartBlock;
        uint256 endBlock = startblock + lifetime;
        uint256 id = totalSupply();
        theMaster.deposit(2, nurseType.power, id);
        nurses.push(Nurse({nurseType: _nurseType, endBlock: endBlock, lastClaimedBlock: startblock}));
        supportingRoute[id] = id;
        emit ChangeSupportingRoute(id, id);
        _mint(msg.sender, id);
        emit ElongateLifetime(id, lifetime, 0, endBlock);
    }

    function assembleWithPermit(
        uint256 nurseType,
        uint256 _parts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        nursePart.permit(msg.sender, address(this), deadline, v, r, s);
        assemble(nurseType, _parts);
    }

    function elongateLifetime(uint256[] calldata ids, uint256[] calldata parts) external override {
        require(ids.length == parts.length, "CloneNurses: Invalid parameters");
        claim(ids);
        for (uint256 i = 0; i < ids.length; i += 1) {
            require(parts[i] > 0, "CloneNurses: Invalid amounts of parts");
            Nurse storage nurse = nurses[ids[i]];
            uint256 _nurseType = nurse.nurseType;
            NurseType storage nurseType = nurseTypes[_nurseType];

            nursePart.safeTransferFrom(msg.sender, address(this), _nurseType, parts[i], "");
            nursePart.burn(_nurseType, parts[i]);

            uint256 oldEndBlock = nurse.endBlock;
            uint256 from;
            if (block.number <= oldEndBlock) from = oldEndBlock;
            else from = block.number;

            uint256 rechagedLifetime = ((nurseType.lifetime * parts[i]) / (nurseType.partCount - 1));
            uint256 newEndBlock = from + rechagedLifetime;
            nurse.endBlock = newEndBlock;
            emit ElongateLifetime(ids[i], rechagedLifetime, oldEndBlock, newEndBlock);
        }
    }

    function destroy(uint256[] calldata ids, uint256[] calldata toIds) external override {
        require(ids.length == toIds.length, "CloneNurses: Invalid parameters");
        for (uint256 i = 0; i < ids.length; i += 1) {
            require(msg.sender == ownerOf(ids[i]), "CloneNurses: Forbidden");
            uint256 power = supportedPower[ids[i]];
            if (power == 0) {
                supportingRoute[ids[i]] = type(uint256).max;
                emit ChangeSupportingRoute(ids[i], type(uint256).max);
            } else {
                require(toIds[i] != ids[i], "CloneNurses: Invalid id, toId");
                require(_exists(toIds[i]), "CloneNurses: Invalid toId");

                supportingRoute[ids[i]] = toIds[i];
                emit ChangeSupportingRoute(ids[i], toIds[i]);
                supportedPower[toIds[i]] += power;
                supportedPower[ids[i]] = 0;
                emit ChangeSupportedPower(toIds[i], int256(power));
            }
            NurseType storage nurseType = nurseTypes[nurses[ids[i]].nurseType];

            uint256 balanceBefore = maidCoin.balanceOf(address(this));
            theMaster.withdraw(2, nurseType.power, ids[i]);
            uint256 balanceAfter = maidCoin.balanceOf(address(this));
            uint256 reward = balanceAfter - balanceBefore;
            _claim(ids[i], reward);

            theMaster.mint(msg.sender, nurseType.destroyReturn);
            _burn(ids[i]);
            delete nurses[ids[i]];
        }
    }

    function claim(uint256[] calldata ids) public override {
        for (uint256 i = 0; i < ids.length; i += 1) {
            require(msg.sender == ownerOf(ids[i]), "CloneNurses: Forbidden");
            uint256 balanceBefore = maidCoin.balanceOf(address(this));
            theMaster.deposit(2, 0, ids[i]);
            uint256 balanceAfter = maidCoin.balanceOf(address(this));
            uint256 reward = balanceAfter - balanceBefore;
            _claim(ids[i], reward);
        }
    }

    function _claim(uint256 id, uint256 reward) internal {
        if (reward == 0) return;
        else {
            Nurse storage nurse = nurses[id];
            uint256 endBlock = nurse.endBlock;
            uint256 lastClaimedBlock = nurse.lastClaimedBlock;
            uint256 burningReward;
            uint256 claimableReward;
            if (endBlock <= lastClaimedBlock) burningReward = reward;
            else if (endBlock < block.number) {
                claimableReward = (reward * (endBlock - lastClaimedBlock)) / (block.number - lastClaimedBlock);
                burningReward = reward - claimableReward;
            } else claimableReward = reward;

            if (burningReward > 0) maidCoin.burn(burningReward);
            if (claimableReward > 0) maidCoin.transfer(msg.sender, claimableReward);
            nurse.lastClaimedBlock = block.number;
            emit Claim(id, msg.sender, claimableReward);
        }
    }

    function pendingReward(uint256 id) external view override returns (uint256 claimableReward) {
        require(_exists(id), "CloneNurses: Invalid id");
        uint256 reward = theMaster.pendingReward(2, id);

        if (reward == 0) return 0;
        else {
            Nurse storage nurse = nurses[id];
            uint256 endBlock = nurse.endBlock;
            uint256 lastClaimedBlock = nurse.lastClaimedBlock;
            if (endBlock <= lastClaimedBlock) return 0;
            else if (endBlock < block.number) {
                claimableReward = (reward * (endBlock - lastClaimedBlock)) / (block.number - lastClaimedBlock);
            } else claimableReward = reward;
        }
    }

    function setSupportingTo(
        address supporter,
        uint256 to,
        uint256 amounts
    ) public override {
        require(msg.sender == address(theMaster), "CloneNurses: Forbidden");
        require(_exists(to), "CloneNurses: Invalid target");
        supportingTo[supporter] = to;
        emit SupportTo(supporter, to);

        if (amounts > 0) {
            supportedPower[to] += amounts;
            emit ChangeSupportedPower(to, int256(amounts));
        }
    }

    function findSupportingTo(address supporter) external view override returns (address, uint256) {
        uint256 _supportingTo = supportingTo[supporter];
        uint256 _route = supportingRoute[_supportingTo];
        if (_route == _supportingTo) return (ownerOf(_supportingTo), _supportingTo);
        while (_route != _supportingTo) {
            _supportingTo = _route;
            _route = supportingRoute[_supportingTo];
        }
        return (ownerOf(_supportingTo), _supportingTo);
    }

    function checkSupportingRoute(address supporter) public override returns (address, uint256) {
        uint256 _supportingTo = supportingTo[supporter];
        uint256 _route = supportingRoute[_supportingTo];
        if (_route == _supportingTo) return (ownerOf(_supportingTo), _supportingTo);
        uint256 initialSupportTo = _supportingTo;
        while (_route != _supportingTo) {
            _supportingTo = _route;
            _route = supportingRoute[_supportingTo];
        }
        supportingTo[supporter] = _supportingTo;
        supportingRoute[initialSupportTo] = _supportingTo;
        emit ChangeSupportingRoute(initialSupportTo, _supportingTo);
        emit SupportTo(supporter, _supportingTo);
        return (ownerOf(_supportingTo), _supportingTo);
    }

    function changeSupportedPower(address supporter, int256 power) public override {
        require(msg.sender == address(theMaster), "CloneNurses: Forbidden");
        (, uint256 id) = checkSupportingRoute(supporter);
        int256 _supportedPower = int256(supportedPower[id]);
        if (power < 0) require(_supportedPower >= (-power), "CloneNurses: Outranged power");
        _supportedPower += power;
        supportedPower[id] = uint256(_supportedPower);
        emit ChangeSupportedPower(id, power);
    }

    function recordRewardsTransfer(
        address supporter,
        uint256 id,
        uint256 amounts
    ) internal {
        totalRewardsFromSupporters[id] += amounts;
        emit TransferSupportingRewards(supporter, id, amounts);
    }

    function shareRewards(
        uint256 pending,
        address supporter,
        uint8 supportingRatio
    ) public override returns (address nurseOwner, uint256 amountToNurseOwner) {
        require(msg.sender == address(theMaster), "CloneNurses: Forbidden");
        amountToNurseOwner = (pending * supportingRatio) / 100;
        uint256 _supportTo;
        if (amountToNurseOwner > 0) {
            (nurseOwner, _supportTo) = checkSupportingRoute(supporter);
            recordRewardsTransfer(supporter, _supportTo, amountToNurseOwner);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, CloneNurseEnumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC1155Receiver, IERC165)
        returns (bool)
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
        return (royaltyReceiver, (_salePrice * royaltyFee) / 1000);
    }

    function setRoyaltyInfo(address _receiver, uint256 _royaltyFee) external onlyOwner {
        royaltyReceiver = _receiver;
        royaltyFee = _royaltyFee;
    }
    
    function exists(uint256 id) external view override returns (bool) {
        return _exists(id);
    }
}
