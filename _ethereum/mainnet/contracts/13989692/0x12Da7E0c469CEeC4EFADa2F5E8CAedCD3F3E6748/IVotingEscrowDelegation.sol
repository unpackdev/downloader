// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve VotingEscrowDelegation contract  */
interface IVotingEscrowDelegation {

    function isApprovedForAll(address owner, address operator) external view returns(bool);

    function ownerOf(uint256 tokenId) external view returns(address);

    function balanceOf(uint256 tokenId) external view returns(uint256);

    function token_of_delegator_by_index(address delegator, uint256 index) external view returns(uint256);

    function total_minted(address delegator) external view returns(uint256);

    function grey_list(address receiver, address delegator) external view returns(bool);

    function setApprovalForAll(address _operator, bool _approved) external;

    function create_boost(
        address _delegator,
        address _receiver,
        int256 _percentage,
        uint256 _cancel_time,
        uint256 _expire_time,
        uint256 _id
    ) external;

    function extend_boost(
        uint256 _token_id,
        int256 _percentage,
        uint256 _cancel_time,
        uint256 _expire_time
    ) external;

    function burn(uint256 _token_id) external;

    function cancel_boost(uint256 _token_id) external;

    function batch_cancel_boosts(uint256[256] memory _token_ids) external;

    function adjusted_balance_of(address _account) external view returns(uint256);

    function delegated_boost(address _account) external view returns(uint256);

    function token_boost(uint256 _token_id) external view returns(int256);

    function token_cancel_time(uint256 _token_id) external view returns(uint256);

    function token_expiry(uint256 _token_id) external view returns(uint256);

    function get_token_id(address _delegator, uint256 _id) external view returns(uint256);

}