// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FMaker.sol";
import "./CMaker.sol";
import "./IMcdManager.sol";
import "./IVat.sol";
import "./IJug.sol";
import "./FIsDebtAmtDust.sol";
import "./FDebtCeilingIsReached.sol";
import "./DSMath.sol";

contract MakerResolver {
    /// @dev Return Debt in wad of the vault associated to the vaultId.
    function getMakerVaultRawDebt(uint256 _vaultId)
        public
        view
        returns (uint256)
    {
        return _getMakerRawVaultDebt(_vaultId);
    }

    function getMakerVaultDebt(uint256 _vaultId) public view returns (uint256) {
        return _getMakerVaultDebt(_vaultId);
    }

    /// @dev Return Collateral in wad of the vault associated to the vaultId.
    function getMakerVaultCollateralBalance(uint256 _vaultId)
        public
        view
        returns (uint256)
    {
        return _getMakerVaultCollateralBalance(_vaultId);
    }

    function vaultWillBeSafe(
        uint256 _vaultId,
        uint256 _colAmt,
        uint256 _daiDebtAmt
    ) public view returns (bool) {
        return _vaultWillBeSafe(_vaultId, _colAmt, _daiDebtAmt);
    }

    function newVaultWillBeSafe(
        string memory _colType,
        uint256 _colAmt,
        uint256 _daiDebtAmt
    ) public view returns (bool) {
        return _newVaultWillBeSafe(_colType, _colAmt, _daiDebtAmt);
    }

    function getMaxDebtAmt(string memory _colType)
        public
        view
        returns (uint256)
    {
        IMcdManager manager = IMcdManager(MCD_MANAGER);
        IVat vat = IVat(manager.vat());
        IJug jug = IJug(JUG);
        bytes32 ilk = _stringToBytes32(_colType);
        (uint256 art, uint256 rate, , uint256 line, ) = vat.ilks(ilk);

        (uint256 duty, uint256 rho) = jug.ilks(ilk);
        uint256 base = jug.base();

        return
            (line -
                (art *
                    rmul(
                        // solhint-disable-next-line not-rely-on-time
                        rpow(base + duty, block.timestamp - rho, 10**27),
                        rate
                    ))) / 1e27;
    }

    // solhint-disable function-max-lines, ordering
    function rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) public pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := b
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := b
                        }
                        default {
                            z := x
                        }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(
                                iszero(iszero(x)),
                                iszero(eq(div(zx, x), z))
                            ) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
        }
    }

    function debtAmtIsDust(
        uint256 _destVaultId,
        string memory _colType,
        uint256 _daiDebtAmt
    ) public view returns (bool) {
        return _isDebtAmtDustExplicit(_destVaultId, _colType, _daiDebtAmt);
    }

    function debtCeilingIsReached(
        uint256 _destVaultId,
        string memory _destColType,
        uint256 _daiDebtAmt
    ) public view returns (bool) {
        return
            _debtCeilingIsReachedExplicit(
                _destVaultId,
                _destColType,
                _daiDebtAmt
            );
    }
}
