// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

interface IPSM {
    // @dev Get the fee for selling USDC to DAI in PSM
    // @return tin toll in [wad]
    function tin() external view returns (uint256);

    // @dev Get the fee for selling DAI to USDC in PSM
    // @return tout toll out [wad]
    function tout() external view returns (uint256);

    // @dev Get the address of the PSM state Vat
    // @return address of the Vat
    function vat() external view returns (address);

    // @dev Get the address of the underlying vault powering PSM
    // @return address of gemJoin contract
    function gemJoin() external view returns (address);

    // @dev Get the address of DAI
    // @return address of DAI contract
    function dai() external view returns (address);

    // @dev Sell USDC for DAI
    // @param usr The address of the account trading USDC for DAI.
    // @param gemAmt The amount of USDC to sell in USDC base units
    function sellGem(address usr, uint256 gemAmt) external;

    // @dev Buy USDC for DAI
    // @param usr The address of the account trading DAI for USDC
    // @param gemAmt The amount of USDC to buy in USDC base units
    function buyGem(address usr, uint256 gemAmt) external;
}

interface IVAT {
    // @dev Get a collateral type by identifier
    // @param ilkIdentifier bytes32 identifier. Example: ethers.utils.formatBytes32String("PSM-USDC-A")
    // @return ilk
    // @return ilk.Art Total Normalised Debt in wad
    // @return ilk.rate Accumulated Rates in ray
    // @return ilk.spot Price with Safety Margin in ray
    // @return ilk.line Debt Ceiling in rad
    // @return ilk.dust Urn Debt Floor in rad
    function ilks(bytes32 ilkIdentifier)
        external
        view
        returns (
            uint256 Art,
            uint256 rate,
            uint256 spot,
            uint256 line,
            uint256 dust
        );
}

contract MakerPSMSampler {
    using SafeMath for uint256;

    /// @dev Information about which PSM module to use
    struct MakerPsmInfo {
        address psmAddress;
        bytes32 ilkIdentifier;
        address gemTokenAddress;
    }

    /// @dev Gas limit for MakerPsm calls.
    uint256 private constant MAKER_PSM_CALL_GAS = 300e3; // 300k

    // Maker units
    // wad: fixed point decimal with 18 decimals (for basic quantities, e.g. balances)
    uint256 private constant WAD = 10**18;
    // ray: fixed point decimal with 27 decimals (for precise quantites, e.g. ratios)
    uint256 private constant RAY = 10**27;
    // rad: fixed point decimal with 45 decimals (result of integer multiplication with a wad and a ray)
    uint256 private constant RAD = 10**45;

    // See https://github.com/makerdao/dss/blob/master/DEVELOPING.m

    /// @dev Sample sell quotes from Maker PSM
    function sampleSellsFromMakerPsm(
        MakerPsmInfo memory psmInfo,
        address takerToken,
        address makerToken,
        uint256[] memory takerTokenAmounts
    ) public view returns (uint256[] memory makerTokenAmounts) {
        IPSM psm = IPSM(psmInfo.psmAddress);
        IVAT vat = IVAT(psm.vat());

        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);

        if (makerToken != psm.dai() && takerToken != psm.dai()) {
            return makerTokenAmounts;
        }

        for (uint256 i = 0; i < numSamples; i++) {
            uint256 buyAmount = _samplePSMSell(
                psmInfo,
                makerToken,
                takerToken,
                takerTokenAmounts[i],
                psm,
                vat
            );

            if (buyAmount == 0) {
                break;
            }
            makerTokenAmounts[i] = buyAmount;
        }
    }

    function _samplePSMSell(
        MakerPsmInfo memory psmInfo,
        address makerToken,
        address takerToken,
        uint256 takerTokenAmount,
        IPSM psm,
        IVAT vat
    ) private view returns (uint256) {
        (
            uint256 totalDebtInWad,
            ,
            ,
            uint256 debtCeilingInRad,
            uint256 debtFloorInRad
        ) = vat.ilks(psmInfo.ilkIdentifier);
        uint256 gemTokenBaseUnit = uint256(1e6);

        if (takerToken == psmInfo.gemTokenAddress) {
            // Simulate sellGem
            // Selling USDC to the PSM, increasing the total debt
            // Convert USDC 6 decimals to 18 decimals [wad]
            uint256 takerTokenAmountInWad = takerTokenAmount.mul(1e12);

            uint256 newTotalDebtInRad = totalDebtInWad
                .add(takerTokenAmountInWad)
                .mul(RAY);

            // PSM is too full to fit
            if (newTotalDebtInRad >= debtCeilingInRad) {
                return 0;
            }

            uint256 feeInWad = takerTokenAmountInWad.mul(psm.tin()).div(WAD);
            uint256 makerTokenAmountInWad = takerTokenAmountInWad.sub(feeInWad);

            return makerTokenAmountInWad;
        } else if (makerToken == psmInfo.gemTokenAddress) {
            // Simulate buyGem
            // Buying USDC from the PSM, decreasing the total debt
            // Selling DAI for USDC, already in 18 decimals [wad]
            uint256 takerTokenAmountInWad = takerTokenAmount;
            if (takerTokenAmountInWad > totalDebtInWad) {
                return 0;
            }
            uint256 newTotalDebtInRad = totalDebtInWad
                .sub(takerTokenAmountInWad)
                .mul(RAY);

            // PSM is empty, not enough USDC to buy from it
            if (newTotalDebtInRad <= debtFloorInRad) {
                return 0;
            }

            uint256 feeDivisorInWad = WAD.add(psm.tout()); // eg. 1.001 * 10 ** 18 with 0.1% tout;
            uint256 makerTokenAmountInGemTokenBaseUnits = takerTokenAmountInWad
                .mul(gemTokenBaseUnit)
                .div(feeDivisorInWad);

            return makerTokenAmountInGemTokenBaseUnits;
        }

        return 0;
    }
}
