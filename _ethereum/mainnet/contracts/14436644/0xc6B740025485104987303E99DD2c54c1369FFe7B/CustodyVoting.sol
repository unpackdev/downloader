// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./DelegateRegistry.sol";

contract CustodyVoting is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public immutable tokenAddress;
    DelegateRegistry public immutable DELEGATE_REGISTRY;
    bytes32 public immutable SPACE_NAME;
    mapping(address => EnumerableSet.AddressSet) private delegation;

    event AddDelegation(address _delegate, address _delegator);
    event RemoveDelegation(address _delegate, address _delegator);
    event RemoveAllDelegation(address _delegate);

    constructor(address _tokenAddress, address _delegateRegistry, bytes32 _spaceName) {
        require(_tokenAddress != address(0), "token address cannot be zero");
        require(_delegateRegistry != address(0), "delegate registry address cannot be zero");
        tokenAddress = IERC20(_tokenAddress);
        DELEGATE_REGISTRY = DelegateRegistry(_delegateRegistry);
        SPACE_NAME = _spaceName;
    }

    function addDelegationForAddress(address _delegate, address[] calldata _delegators) external onlyOwner {
        for(uint256 i; i < _delegators.length; ++i){
            delegation[_delegate].add(_delegators[i]);
            emit AddDelegation(_delegate, _delegators[i]);
        }
    }

    function removeDelegationForAddress(address _delegate, address _delegator) external onlyOwner {
        require(delegation[_delegate].contains(_delegator), "The delegate is not added");

        delegation[_delegate].remove(_delegator);
        emit RemoveDelegation(_delegate, _delegator);
    }

    function removeAllDelegationForAddress(address _delegate) external onlyOwner {
        delete delegation[_delegate];
        emit RemoveAllDelegation(_delegate);
    }

    function getDelegationForAddress(address _address) external view returns (address[] memory) {
        EnumerableSet.AddressSet storage set = delegation[_address];
        address[] memory result = new address[](set.length());

        for(uint256 i; i < set.length(); ++i){
            result[i] = set.at(i);
        }
        return result;
    }

    function getVotes(address _address) external view returns (uint256) {
        EnumerableSet.AddressSet storage set = delegation[_address];
        uint256 votes;

        for(uint256 i; i < set.length(); ++i){
            if(DELEGATE_REGISTRY.delegation(set.at(i), SPACE_NAME) == address(0)){
                votes += tokenAddress.balanceOf(set.at(i));
            }
        }
        return votes;
    }
}