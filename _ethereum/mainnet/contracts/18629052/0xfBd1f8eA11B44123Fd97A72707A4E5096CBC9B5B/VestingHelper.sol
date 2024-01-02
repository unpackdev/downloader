// SPDX-License-Identifier: MIT

interface ITokenVestingStaking {
    //////////////////////////////////////////////////////////////
    //                                                          //
    //                Non-state-changing functions              //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getBeneficiary() external view returns (address);

    function getRevoker() external view returns (address);
}
contract VestingHelper {
    

    constructor() {}

    function getBeneficiaries(address[] memory vestingContracts) external returns (address[] memory)  {
        address[] memory beneficiaries = new address[](vestingContracts.length);
        for (uint i = 0; i < vestingContracts.length; i++) {
            beneficiaries[i] = ITokenVestingStaking(vestingContracts[i]).getBeneficiary();
        }
        return beneficiaries;
    }
}