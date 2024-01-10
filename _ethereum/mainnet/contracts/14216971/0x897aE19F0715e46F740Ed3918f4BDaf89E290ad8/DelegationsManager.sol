// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IDelegationsManager.sol";
import "./LazyInitCapableElement.sol";
import "./IFactory.sol";
import "./IERC20Metadata.sol";
import "./GeneralUtilities.sol";
import "./Item.sol";
import "./IOrganization.sol";
import "./IDelegationTokensManager.sol";
import "./KnowledgeBase.sol";
import "./KnowledgeBase.sol";
import "./IERC1155.sol";
import "./draft-IERC20Permit.sol";
import "./ERC20Burnable.sol";

contract DelegationsManager is IDelegationsManager, LazyInitCapableElement {
    using ReflectionUtilities for address;
    using Getters for IOrganization;
    using DelegationGetters for IOrganization;
    using TransferUtilities for address;

    uint256 private constant ONE_HUNDRED = 1e18;

    address private _collection;
    uint256 private _objectId;

    address private _treasuryManagerModelAddress;

    mapping(address => address) public override treasuryOf;
    mapping(uint256 => DelegationData) private _storage;
    mapping(address => uint256) private _index;
    uint256 public override size;

    uint256 public override maxSize;

    uint256 public override executorRewardPercentage;

    mapping(address => bool) public override factoryIsAllowed;
    mapping(address => bool) public override isBanned;

    bytes32 public flusherKey;

    mapping(address => uint256) private _paidFor;
    mapping(address => mapping(address => uint256)) private _retriever;

    uint256 private _attachInsurance;
    address private _attachInsuranceRetriever;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override returns (bytes memory lazyInitResponse) {

        (maxSize, _treasuryManagerModelAddress, lazyInitResponse) = abi.decode(lazyInitData, (uint256, address, bytes));

        (executorRewardPercentage, _collection, _objectId, lazyInitResponse) = abi.decode(lazyInitResponse, (uint256, address, uint256, bytes));

        (_attachInsurance, _attachInsuranceRetriever, flusherKey, lazyInitResponse) = abi.decode(lazyInitResponse, (uint256, address, bytes32, bytes));

        if(lazyInitResponse.length > 0) {
            (address[] memory allowedFactories, address[] memory bannedDelegations) = abi.decode(lazyInitResponse, (address[], address[]));

            for(uint256 i = 0; i < allowedFactories.length; i++) {
                factoryIsAllowed[allowedFactories[i]] = true;
            }
            for(uint256 i = 0; i < bannedDelegations.length; i++) {
                isBanned[bannedDelegations[i]] = true;
            }
        }
        lazyInitResponse = "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IDelegationsManager).interfaceId ||
            interfaceId == this.split.selector ||
            interfaceId == this.supportedToken.selector ||
            interfaceId == this.setSupportedToken.selector ||
            interfaceId == this.maxSize.selector ||
            interfaceId == this.setMaxSize.selector ||
            interfaceId == this.size.selector ||
            interfaceId == this.list.selector ||
            interfaceId == this.partialList.selector ||
            interfaceId == this.listByAddresses.selector ||
            interfaceId == this.listByIndices.selector ||
            interfaceId == this.exists.selector ||
            interfaceId == this.treasuryOf.selector ||
            interfaceId == this.get.selector ||
            interfaceId == this.getByIndex.selector ||
            interfaceId == this.set.selector ||
            interfaceId == this.remove.selector ||
            interfaceId == this.executorRewardPercentage.selector ||
            interfaceId == this.getSplit.selector ||
            interfaceId == this.factoryIsAllowed.selector ||
            interfaceId == this.setFactoriesAllowed.selector ||
            interfaceId == this.isBanned.selector ||
            interfaceId == this.ban.selector ||
            interfaceId == this.isValid.selector ||
            interfaceId == this.payFor.selector ||
            interfaceId == this.retirePayment.selector ||
            interfaceId == this.attachInsurance.selector ||
            interfaceId == this.setAttachInsurance.selector;
    }

    receive() external payable {
    }

    function supportedToken() external override view returns(address, uint256) {
        return (_collection, _objectId);
    }

    function setSupportedToken(address collection, uint256 objectId) external override authorizedOnly {
        _collection = collection;
        _objectId = objectId;
    }

    function setMaxSize(uint256 newValue) external override authorizedOnly returns(uint256 oldValue) {
        oldValue = maxSize;
        maxSize = newValue;
    }

    function list() override public view returns (DelegationData[] memory) {
        return partialList(0, size);
    }

    function partialList(uint256 start, uint256 offset) override public view returns (DelegationData[] memory delegations) {
        (uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) = BehaviorUtilities.calculateProjectedArraySizeAndLoopUpperBound(size, start, offset);
        if(projectedArraySize > 0) {
            delegations = new DelegationData[](projectedArraySize);
            uint256 cursor = 0;
            for(uint256 i = start; i < projectedArrayLoopUpperBound; i++) {
                delegations[cursor++] = _storage[i];
            }
        }
    }

    function listByAddresses(address[] calldata delegationAddresses) override external view returns (DelegationData[] memory delegations) {
        delegations = new DelegationData[](delegationAddresses.length);
        for(uint256 i = 0; i < delegations.length; i++) {
            delegations[i] = _storage[_index[delegationAddresses[i]]];
        }
    }

    function listByIndices(uint256[] memory indices) override public view returns (DelegationData[] memory delegations) {
        delegations = new DelegationData[](indices.length);
        for(uint256 i = 0; i < delegations.length; i++) {
            delegations[i] = _storage[indices[i]];
        }
    }

    function exists(address delegationAddress) public override view returns(bool result, uint256 index, address treasuryAddress) {
        treasuryAddress = treasuryOf[delegationAddress];
        result = delegationAddress != address(0) && _storage[index = _index[delegationAddress]].location == delegationAddress;
    }

    function get(address delegationAddress) external override view returns(DelegationData memory) {
        return _storage[_index[delegationAddress]];
    }

    function getByIndex(uint256 index) override external view returns(DelegationData memory) {
        return _storage[index];
    }

    function split(address executorRewardReceiver) external override {
        require(address(this).balance > 0, "No ETH");
        (address[] memory receivers, uint256[] memory values) = getSplit(executorRewardReceiver);
        if(receivers.length == 0) {
            return;
        }
        for(uint256 i = 0; i < receivers.length; i++) {
            if(values[i] == 0) {
                continue;
            }
            receivers[i].submit(values[i], "");
        }
    }

    function set() external override {
        _set(msg.sender);
    }

    function remove(address[] calldata delegationAddresses) external override authorizedOnly returns(DelegationData[] memory removedDelegations) {
        removedDelegations = new DelegationData[](delegationAddresses.length);
        for(uint256 i = 0; i < delegationAddresses.length; i++) {
            removedDelegations[i] = _remove(delegationAddresses[i]);
        }
    }

    function removeAll() external override authorizedOnly {
        while(size > 0) {
            _remove(size - 1);
        }
    }

    function setFactoriesAllowed(address[] memory factoryAddresses, bool[] memory allowed) external override authorizedOnly {
        for(uint256 i = 0; i < factoryAddresses.length; i++) {
            emit Factory(factoryAddresses[i], factoryIsAllowed[factoryAddresses[i]] = allowed[i]);
        }
    }

    function ban(address[] memory productAddresses) external override authorizedOnly {
        for(uint256 i = 0; i < productAddresses.length; i++) {
            isBanned[productAddresses[i]] = true;
            _remove(productAddresses[i]);
            _burn(productAddresses[i]);
        }
    }

    function isValid(address delegationAddress) public override view returns(bool) {
        if(isBanned[delegationAddress]) {
            return false;
        }
        IFactory factory = IFactory(ILazyInitCapableElement(delegationAddress).initializer());
        if(!factoryIsAllowed[address(factory)]) {
            return false;
        }
        if(factory.deployer(delegationAddress) == address(0)) {
            return false;
        }
        return _paidFor[delegationAddress] >= attachInsurance();
    }

    function getSplit(address executorRewardReceiver) public override view returns (address[] memory receivers, uint256[] memory values) {

        (address[] memory treasuries, uint256[] memory treasuryPercentages) = getSituation();

        receivers = new address[](treasuries.length + (executorRewardPercentage == 0 ? 1 : 2));
        values = new uint256[](receivers.length);

        uint256 availableAmount = address(this).balance;
        uint256 index = 0;

        if(executorRewardPercentage > 0) {
            receivers[index] = executorRewardReceiver != address(0) ? executorRewardReceiver : msg.sender;
            values[index] = _calculatePercentage(availableAmount, executorRewardPercentage);
            availableAmount -= values[index++];
        }

        uint256 remainingAmount = availableAmount;

        for(uint256 i = 0; i < treasuries.length; i++) {
            receivers[index] = treasuries[i];
            values[index] = _calculatePercentage(availableAmount, treasuryPercentages[i]);
            remainingAmount -= values[index++];
        }

        receivers[index] = _flusher();
        values[index] = remainingAmount;
    }

    function getSituation() public override view returns(address[] memory treasuries, uint256[] memory treasuryPercentages) {
        IDelegationsManager.DelegationData[] memory delegations = list();
        uint256 totalSupply;
        uint256[] memory totalSupplyArray = new uint256[](delegations.length);
        treasuries = new address[](delegations.length);
        for(uint256 i = 0; i < delegations.length; i++) {
            totalSupplyArray[i] = _getDelegationTotalSupply(delegations[i].location);
            totalSupply += totalSupplyArray[i];
            treasuries[i] = delegations[i].treasury;
        }
        treasuryPercentages = new uint256[](delegations.length);
        for(uint256 i = 0; i < treasuryPercentages.length; i++) {
            treasuryPercentages[i] = _retrievePercentage(totalSupplyArray[i], totalSupply);
        }
    }

    function attachInsurance() public override view returns (uint256) {
        if(_attachInsuranceRetriever != address(0)) {
            (bool result, bytes memory response) = _attachInsuranceRetriever.staticcall(abi.encodeWithSignature("get()"));
            if(!result || response.length == 0) {
                return 0;
            }
            return abi.decode(response, (uint256));
        }
        return _attachInsurance;
    }

    function setAttachInsurance(uint256 value) external override authorizedOnly returns (uint256 oldValue) {
        oldValue = _attachInsurance;
        _attachInsurance = value;
    }

    function paidFor(address delegationAddress, address retriever) external override view returns(uint256 totalPaid, uint256 retrieverPaid) {
        totalPaid = _paidFor[delegationAddress];
        retrieverPaid = _retriever[delegationAddress][retriever];
    }

    function onERC1155Received(address, address from, uint256 objectId, uint256 amount, bytes calldata data) external returns(bytes4) {
        require(msg.sender == _collection && objectId == _objectId, "unauthorized");
        (address delegationAddress, address retriever) = abi.decode(data, (address, address));
        _payFor(delegationAddress, from, retriever, amount);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address from, uint256[] calldata objectIds, uint256[] calldata amounts, bytes calldata data) external returns (bytes4) {
        require(_collection == msg.sender, "Unauthorized");
        bytes[] memory payloads = abi.decode(data, (bytes[]));
        for(uint256 i = 0; i < objectIds.length; i++) {
            require(objectIds[i] == _objectId, "Unauthorized");
            (address delegationAddress, address retriever) = abi.decode(payloads[i], (address, address));
            _payFor(delegationAddress, from, retriever, amounts[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function payFor(address delegationAddress, uint256 amount, bytes memory permitSignature, address retriever) external payable override {
        require(_collection == address(0), "Use safeTransferFrom");
        address erc20TokenAddress = address(uint160(_objectId));
        require(erc20TokenAddress != address(0) ? msg.value == 0 : msg.value == amount, "ETH");
        if(erc20TokenAddress != address(0) && permitSignature.length > 0) {
            (uint8 v, bytes32 r, bytes32 s, uint256 deadline) = abi.decode(permitSignature, (uint8, bytes32, bytes32, uint256));
            IERC20Permit(erc20TokenAddress).permit(msg.sender, address(this), amount, deadline, v, r, s);
        }
        _payFor(delegationAddress, msg.sender, retriever, _safeTransferFrom(erc20TokenAddress, amount));
    }

    function retirePayment(address delegationAddress, address receiver, bytes memory data) external override {
        require(delegationAddress != address(0), "Delegation");
        require(!isBanned[delegationAddress], "banned");
        (bool result,,) = exists(delegationAddress);
        require(!result, "still attached");
        address realReceiver = receiver != address(0) ? receiver : msg.sender;
        uint256 amount = _retriever[delegationAddress][msg.sender];
        require(amount > 0, "Amount");
        _retriever[delegationAddress][msg.sender] = 0;
        _paidFor[delegationAddress] = _paidFor[delegationAddress] - amount;
        _giveBack(realReceiver, amount, data);
    }

    function _giveBack(address receiver, uint256 amount, bytes memory data) private {
        if(_collection == address(0)) {
            address(uint160(_objectId)).safeTransfer(receiver, amount);
        } else {
            IERC1155(_collection).safeTransferFrom(address(this), receiver, _objectId, amount, data);
        }
    }

    function _safeTransferFrom(address erc20TokenAddress, uint256 value) private returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return value;
        }
        uint256 previousBalance = erc20TokenAddress.balanceOf(address(this));
        erc20TokenAddress.safeTransferFrom(msg.sender, address(this), value);
        uint256 actualBalance = erc20TokenAddress.balanceOf(address(this));
        require(actualBalance > previousBalance);
        return actualBalance - previousBalance;
    }

    function _payFor(address delegationAddress, address from, address retriever, uint256 amount) private {
        require(amount > 0, "value");
        require(delegationAddress != address(0), "Delegation");
        require(!isBanned[delegationAddress], "banned");
        _paidFor[delegationAddress] = _paidFor[delegationAddress] + amount;
        address realRetriever = retriever != address(0) ? retriever : from;
        _retriever[delegationAddress][realRetriever] = _retriever[delegationAddress][realRetriever] + amount;
        emit PaidFor(delegationAddress, from, realRetriever, amount);
    }

    function _set(address delegationAddress) private {
        require(maxSize == 0 || size < maxSize, "full");
        (bool result,,) = exists(delegationAddress);
        require(!result, "exists");
        require(isValid(delegationAddress), "not valid");
        _index[delegationAddress] = size++;
        address treasuryAddress = treasuryOf[delegationAddress];
        if(treasuryAddress == address(0)) {
            ILazyInitCapableElement(treasuryOf[delegationAddress] = treasuryAddress = _treasuryManagerModelAddress.clone()).lazyInit(abi.encode(delegationAddress, bytes("")));
        }
        _storage[_index[delegationAddress]] = DelegationData({
            location : delegationAddress,
            treasury : treasuryAddress
        });
        emit DelegationSet(delegationAddress, treasuryAddress);
    }

    function _remove(address delegationAddress) private returns(DelegationData memory removedDelegation) {
        (bool result, uint256 index,) = exists(delegationAddress);
        removedDelegation = result ? _remove(index) : removedDelegation;
    }

    function _remove(uint256 index) private returns(DelegationData memory removedDelegation) {
        if(index >= size) {
            return removedDelegation;
        }
        delete _index[(removedDelegation = _storage[index]).location];
        if(index != --size) {
            DelegationData memory lastEntry = _storage[size];
            _storage[_index[lastEntry.location] = index] = lastEntry;
        }
        delete _storage[size];
    }

    function _getDelegationTotalSupply(address delegationAddress) private view returns(uint256) {
        (address wrappedCollection, uint256 wrappedObjectId) = IOrganization(delegationAddress).tokensManager().wrapped(_collection, _objectId, address(this));
        try Item(wrappedCollection).totalSupply(wrappedObjectId) returns (uint256 ts) {
            return ts;
        } catch {
            return 0;
        }
    }

    function _calculatePercentage(uint256 totalSupply, uint256 percentage) private pure returns(uint256) {
        return (totalSupply * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    function _retrievePercentage(uint256 numerator, uint256 denominator) private pure returns(uint256) {
        if(denominator == 0) {
            return 0;
        }
        return (numerator * ONE_HUNDRED) / denominator;
    }

    function _flusher() private view returns (address flusher) {
        IOrganization org = IOrganization(host);
        if(flusherKey != bytes32(0)) {
            flusher = org.get(flusherKey);
        }
        flusher = flusher != address(0) ? flusher : address(org.treasuryManager());
    }

    function _burn(address delegationsManagerAddress) private {
        uint256 value = _paidFor[delegationsManagerAddress];
        if(value == 0) {
            return;
        }
        _paidFor[delegationsManagerAddress] = 0;
        if(_collection == address(0)) {
            address tokenAddress = address(uint160(_objectId));
            if(tokenAddress == address(0)) {
                tokenAddress.safeTransfer(address(0), value);
                return;
            }
            try ERC20Burnable(tokenAddress).burn(value) {
            } catch {
                (bool result,) = tokenAddress.call(abi.encodeWithSelector(IERC20(tokenAddress).transfer.selector, address(0), value));
                if(!result) {
                    (result,) = tokenAddress.call(abi.encodeWithSelector(IERC20(tokenAddress).transfer.selector, 0x000000000000000000000000000000000000dEaD, value));
                }
            }
            return;
        }
        try Item(_collection).burn(address(this), _objectId, value) {
        } catch {
            try Item(_collection).safeTransferFrom(address(this), address(0), _objectId, value, "") {
            } catch {
                _collection.call(abi.encodeWithSelector(Item(_collection).safeTransferFrom.selector, address(this), 0x000000000000000000000000000000000000dEaD, _objectId, value, bytes("")));
            }
        }
    }
}