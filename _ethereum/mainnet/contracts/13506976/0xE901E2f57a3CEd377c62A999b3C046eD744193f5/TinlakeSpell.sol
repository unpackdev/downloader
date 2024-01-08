// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.6.12;

////// src/spell.sol
/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

/* pragma solidity >=0.6.12; */

////// src/spell.sol
// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
/* pragma solidity >=0.6.12; */

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
    function wards(address) external returns(uint);
}

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
    function update(bytes32 nftID, uint value, uint risk) external;
    function nftID(uint loan) external returns (bytes32);
    function nftValues(bytes32 nftID) external returns(uint);
}

interface PileLike {
    function changeRate(uint loan, uint newRate) external;
}

// This spell makes changes to the tinlake mainnet HTC2 deployment:
// adds new risk groups 
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake GigPool spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public ROOT = 0x3d167bd08f762FD391694c67B5e6aF0868c45538;
    address constant public NAV_FEED = 0x468eb2408c6F24662a291892550952eb0d70b707;
    address constant public PILE = 0x9E39e0130558cd9A01C1e3c7b2c3803baCb59616;
                                                             
    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
       NAVFeedLike navFeed = NAVFeedLike(address(NAV_FEED));
       PileLike pile = PileLike(PILE);
       self = address(this);
       // permissions 
       root.relyContract(NAV_FEED, self); // required to file riskGroups & change discountRate
       root.relyContract(PILE, self); // required to change the interestRates for loans according to new riskGroups
        
        // update Scorecard
        // risk group: 3 - M, APR: 13.00%
        navFeed.file("riskGroup", 3, ONE, ONE, uint256(1000000004122272957889396245), 99.9*10**25);
        // risk group: 4 - W, APR: 11.00%
        navFeed.file("riskGroup", 4, ONE, ONE, uint256(1000000003488077118214104515), 99.9*10**25);
        // risk group: 5 - PC, APR: 10.00%
        navFeed.file("riskGroup", 5, ONE, ONE, uint256(1000000003170979198376458650), 99.9*10**25);
        
        // move all assets from riskGroup 0 to riskGroup 3 & riskGroup 1 to riskGroup 4
        // => move loan 2 & 3 to group 3 & loan 4 to group 4
        uint newRiskGroup3 = 3;
        uint newRiskGroup4 = 4;
        uint loanID2 = 2;
        bytes32 nftIDLoan2 = navFeed.nftID(loanID2);
        uint nftValueLoan2 = navFeed.nftValues(nftIDLoan2);
        navFeed.update(nftIDLoan2, nftValueLoan2, newRiskGroup3);
        pile.changeRate(loanID2, newRiskGroup3);
        
        uint loanID3 = 3;
        bytes32 nftIDLoan3 = navFeed.nftID(loanID3);
        uint nftValueLoan3 = navFeed.nftValues(nftIDLoan3);
        navFeed.update(nftIDLoan3, nftValueLoan3, newRiskGroup3);
        pile.changeRate(loanID3, newRiskGroup3);

        uint loanID4 = 4;
        bytes32 nftIDLoan4 = navFeed.nftID(loanID4);
        uint nftValueLoan4 = navFeed.nftValues(nftIDLoan4);
        navFeed.update(nftIDLoan4, nftValueLoan4, newRiskGroup4);
        pile.changeRate(loanID4, newRiskGroup4);
     }  
}
