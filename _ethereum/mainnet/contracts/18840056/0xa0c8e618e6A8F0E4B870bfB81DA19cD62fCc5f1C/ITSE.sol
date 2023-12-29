// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./ITokenERC1155.sol";
import "./IVesting.sol";

interface ITSE {
  

    struct TSEInfo {
        uint256 amount;
        uint256 price;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 duration;
        address[] userWhitelist;
        address unitOfAccount;
    }

    function initialize(
        address _token,
        uint256 _tokenId,
        TSEInfo calldata _info,
        address _seller,
        address _recipient
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function token() external view returns (address);

    function tokenId() external view returns (uint256);

    function state() external view returns (State);

    function getInfo() external view returns (TSEInfo memory);

    function purchaseOf(address user) external view returns (uint256);

    function getEnd() external view returns (uint256);

    function totalPurchased() external view returns (uint256);

    function isERC1155TSE() external view returns (bool);

    function purchase(uint256 amount) external payable;

    function finishTSE() external;
}
