// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IIssuanceModule{
   event Issue(address _vault, address from, address[] _assets,uint256[] _positionType,uint256[] _amounts);
   event IssueFromVault(address _vault, address from, address[] _assets,uint256[] _positionType,uint256[] _amounts);
   event Redeem(address _vault,address[] _assets,uint256[] _positionType,uint256[]  _amounts);
   function issue(address _vault,address _from,address[] memory _assets,uint256[] memory _positionType,uint256[] memory _amounts) external;
   function issue(address _vault,address[] memory _assets,uint256[] memory _positionType,uint256[] memory _amounts) external;
   function redeem(address _vault,address payable _to,address[] memory _assets,uint256[] memory _positionType,uint256[] memory _amounts) external;
   function issueFromVault(address _vault, address _from, address[] memory _assets, uint256[] memory _positionType, uint256[] memory _amounts) external;
}