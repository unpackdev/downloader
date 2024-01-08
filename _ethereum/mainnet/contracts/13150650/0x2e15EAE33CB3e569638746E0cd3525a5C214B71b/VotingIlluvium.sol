// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./ICorePool.sol";

contract VotingIlluvium {
    string public constant name = "Voting Illuvium";
    string public constant symbol = "vILV";

    uint256 public constant decimals = 18;

    address public constant ILV = 0x767FE9EDC9E0dF98E07454847909b5E959D7ca0E;
    address public constant ILV_POOL = 0x25121EDDf746c884ddE4619b573A7B10714E2a36;
    address public constant LP_POOL = 0x8B4d8443a0229349A9892D4F7CbE89eF5f843F72;
    address public constant TOKEN_LOCKING = 0xd3b23dBDC485E7559235aBC58c0a3e737e4Aa592;

    function balanceOf(address _account) external view returns (uint256 balance) {
        uint256 ilvBalance = IERC20(ILV).balanceOf(_account);
        uint256 ilvPoolBalance = ICorePool(ILV_POOL).balanceOf(_account);
        uint256 lpPoolBalance = _lpToILV(ICorePool(LP_POOL).balanceOf(_account));
        uint256 lockedBalance = IERC20(TOKEN_LOCKING).balanceOf(_account);

        balance = ilvBalance + ilvPoolBalance + lpPoolBalance + lockedBalance;
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(ILV).totalSupply();
    }

    function _lpToILV(uint256 _lpBalance) internal view returns (uint256 ilvAmount) {
          address _poolToken = ICorePool(LP_POOL).poolToken();

          uint256 totalLP = IERC20(_poolToken).totalSupply();
          uint256 ilvInLP = IERC20(ILV).balanceOf(_poolToken);
          ilvAmount= (ilvInLP * _lpBalance) / totalLP;
    }
}
