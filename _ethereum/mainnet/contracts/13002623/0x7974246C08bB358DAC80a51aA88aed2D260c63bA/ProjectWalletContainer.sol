// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./AuthorizedList.sol";
import "./LockableSwap.sol";

contract ProjectWalletContainer is AuthorizedList, LockableSwap {
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public token;

    uint256 private constant shares = 100;

    address[] private projectTeam;
    mapping(address => uint256) private allocatedShares;
    mapping(address => EnumerableSet.AddressSet) private projectTeamMemberWallets;

    EnumerableSet.AddressSet private voteAddToTeam;
    EnumerableSet.AddressSet private voteRemoveFromTeam;

    constructor(address _tokenAddress) AuthorizedList() payable {

        token = IERC20(_tokenAddress);

        authorizedCaller[0x6e61665eb04E6229138df2b4c6d4A5c9606f6C0a] = true;
        authorizedCaller[0xcFbA019149Af2Ab7A3e65DC90f4FE8b1eEF1c73E] = true;
        authorizedCaller[0x2AA102Aff74e54A52d67c1a28827013ca88d9F32] = true;
        authorizedCaller[0x855B455B08095AEf99eC151e4051fD32D1d61631] = true;
        authorizedCaller[0x0fE3E2826827CC859773833111f68F585e4a834a] = true;
        authorizedCaller[0x142E2216b88351a87Aa26A3fD6e128207a6A0439] = true;
        authorizedCaller[0xC030f718f1EeDfac5638153013A54487A238dc67] = true;
        authorizedCaller[0xD348269309fd1959e3E12bE2808d91d4AA582886] = true;
        authorizedCaller[0xDEdF5bf60A4B24f744dCEB248bBE4b69e06DB05e] = true;

        projectTeamMemberWallets[0x6e61665eb04E6229138df2b4c6d4A5c9606f6C0a].add(0x6e61665eb04E6229138df2b4c6d4A5c9606f6C0a);
        projectTeamMemberWallets[0xcFbA019149Af2Ab7A3e65DC90f4FE8b1eEF1c73E].add(0xcFbA019149Af2Ab7A3e65DC90f4FE8b1eEF1c73E);
        projectTeamMemberWallets[0x2AA102Aff74e54A52d67c1a28827013ca88d9F32].add(0x2AA102Aff74e54A52d67c1a28827013ca88d9F32);
        projectTeamMemberWallets[0x855B455B08095AEf99eC151e4051fD32D1d61631].add(0x855B455B08095AEf99eC151e4051fD32D1d61631);
        projectTeamMemberWallets[0x0fE3E2826827CC859773833111f68F585e4a834a].add(0x0fE3E2826827CC859773833111f68F585e4a834a);
        projectTeamMemberWallets[0x142E2216b88351a87Aa26A3fD6e128207a6A0439].add(0x142E2216b88351a87Aa26A3fD6e128207a6A0439);
        projectTeamMemberWallets[0xC030f718f1EeDfac5638153013A54487A238dc67].add(0xC030f718f1EeDfac5638153013A54487A238dc67);
        projectTeamMemberWallets[0xD348269309fd1959e3E12bE2808d91d4AA582886].add(0xD348269309fd1959e3E12bE2808d91d4AA582886);
        projectTeamMemberWallets[0xDEdF5bf60A4B24f744dCEB248bBE4b69e06DB05e].add(0xDEdF5bf60A4B24f744dCEB248bBE4b69e06DB05e);

        projectTeam.push(0x6e61665eb04E6229138df2b4c6d4A5c9606f6C0a);
        projectTeam.push(0xcFbA019149Af2Ab7A3e65DC90f4FE8b1eEF1c73E);
        projectTeam.push(0x2AA102Aff74e54A52d67c1a28827013ca88d9F32);
        projectTeam.push(0x855B455B08095AEf99eC151e4051fD32D1d61631);
        projectTeam.push(0x0fE3E2826827CC859773833111f68F585e4a834a);
        projectTeam.push(0x142E2216b88351a87Aa26A3fD6e128207a6A0439);
        projectTeam.push(0xC030f718f1EeDfac5638153013A54487A238dc67);
        projectTeam.push(0xD348269309fd1959e3E12bE2808d91d4AA582886);
        projectTeam.push(0xDEdF5bf60A4B24f744dCEB248bBE4b69e06DB05e);

        allocatedShares[0x6e61665eb04E6229138df2b4c6d4A5c9606f6C0a] = 20;
        allocatedShares[0xcFbA019149Af2Ab7A3e65DC90f4FE8b1eEF1c73E] = 20;
        allocatedShares[0x2AA102Aff74e54A52d67c1a28827013ca88d9F32] = 20;
        allocatedShares[0x855B455B08095AEf99eC151e4051fD32D1d61631] = 20;
        allocatedShares[0x0fE3E2826827CC859773833111f68F585e4a834a] = 10;
        allocatedShares[0x142E2216b88351a87Aa26A3fD6e128207a6A0439] = 2;
        allocatedShares[0xC030f718f1EeDfac5638153013A54487A238dc67] = 2;
        allocatedShares[0xD348269309fd1959e3E12bE2808d91d4AA582886] = 2;
        allocatedShares[0xDEdF5bf60A4B24f744dCEB248bBE4b69e06DB05e] = 4;
    }

    receive() external payable {}

    fallback() external payable {}

    function collectTokens() external authorized lockTheSwap {
        uint256 teamCount = projectTeam.length;
        address thisAddress = address(this);
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSignature("balanceOf(address)",thisAddress));
        uint256 tokenBal = 0;
        uint256 tokensRemaining = 0;
        if(success){
            tokenBal = abi.decode(data, (uint256));
            tokensRemaining = tokenBal;
        }else{
            return;
        }
        uint256 tokenShare = 0;
        address payable teamMember = payable(address(0));
        for(uint256 i = 0; i < teamCount; i++){
            teamMember = payable(projectTeam[i]);
            if(tokenBal > 1000 && tokensRemaining > 0){
                tokenShare = allocatedShares[teamMember].mul(tokenBal).div(shares);
                if(tokenShare > tokensRemaining){
                    tokenShare = tokensRemaining;
                }
                tokensRemaining = tokensRemaining.sub(tokenShare);
                try token.transfer{gas: gasleft()}(teamMember, tokenShare) {} catch {}
            }
        }
    }

    function collectEth() external authorized lockTheSwap {
        uint256 teamCount = projectTeam.length;
        uint256 ethBal = address(this).balance;
        address payable teamMember = payable(address(0));
        uint256 ethShare = 0;
        for(uint256 i = 0; i < teamCount; i++){
            teamMember = payable(projectTeam[i]);
            if(ethBal > 1000){
                ethShare = allocatedShares[teamMember].mul(ethBal).div(shares);
                if(ethShare > address(this).balance){
                    ethShare = address(this).balance;
                }
                address(teamMember).call{value: ethShare}("");
            }
        }
    }

    function collectSpecificToken(address tokenAddress) external authorized lockTheSwap {
        IERC20 distributionToken = IERC20(tokenAddress);
        uint256 teamCount = projectTeam.length;
        uint256 tokenBal = distributionToken.balanceOf(address(this));
        uint256 ethBal = address(this).balance;
        uint256 ethShare = 0;
        uint256 tokenShare = 0;
        address payable teamMember = payable(address(0));
        for(uint256 i = 0; i < teamCount; i++){
            teamMember = payable(projectTeam[i]);
            if(ethBal > 0){
                ethShare = allocatedShares[teamMember].mul(ethBal).div(shares);
                if(ethShare > address(this).balance){
                    ethShare = address(this).balance;
                }
                address(teamMember).call{value: ethShare}("");
            }
            if(tokenBal > 0){
                tokenShare = allocatedShares[teamMember].mul(tokenBal).div(shares);
                if(tokenShare > distributionToken.balanceOf(address(this))){
                    tokenShare = distributionToken.balanceOf(address(this));
                }
                distributionToken.transfer(teamMember, tokenShare);
            }
        }
    }

    function addSubAddress(address subAddress) external authorized {
        projectTeamMemberWallets[_msgSender()].add(subAddress);
    }

    function setToken(address tokenAddress) external onlyOwner {
        require(address(token) != tokenAddress, "Token is already set to this address");
        token = IERC20(tokenAddress);
    }
}
