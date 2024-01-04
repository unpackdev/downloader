pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Exponential.sol";
import "./SafeERC20.sol";
import "./GasBurner.sol";
import "./CTokenInterface.sol";
import "./ComptrollerInterface.sol";

contract CompBalance is Exponential, GasBurner {
    ComptrollerInterface public constant comp = ComptrollerInterface(
        0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
    );
    address public constant COMP_ADDR = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    uint224 public constant compInitialIndex = 1e36;

    function claimComp(
        address _user,
        address[] memory _cTokensSupply,
        address[] memory _cTokensBorrow
    ) public burnGas(8) {
        _claim(_user, _cTokensSupply, _cTokensBorrow);

        ERC20(COMP_ADDR).transfer(msg.sender, ERC20(COMP_ADDR).balanceOf(address(this)));
    }

    function _claim(
        address _user,
        address[] memory _cTokensSupply,
        address[] memory _cTokensBorrow
    ) internal {
        address[] memory u = new address[](1);
        u[0] = _user;

        comp.claimComp(u, _cTokensSupply, false, true);
        comp.claimComp(u, _cTokensBorrow, true, false);
    }

    function getBalance(address _user, address[] memory _cTokens) public view returns (uint256) {
        uint256 compBalance = 0;

        for (uint256 i = 0; i < _cTokens.length; ++i) {
            compBalance += getSuppyBalance(_cTokens[i], _user);
            compBalance += getBorrowBalance(_cTokens[i], _user);
        }

        compBalance = add_(comp.compAccrued(_user), compBalance);

        compBalance += ERC20(COMP_ADDR).balanceOf(_user);

        return compBalance;
    }

    function getClaimableAssets(address[] memory _cTokens, address _user)
        public
        view
        returns (bool[] memory supplyClaims, bool[] memory borrowClaims)
    {
        supplyClaims = new bool[](_cTokens.length);
        borrowClaims = new bool[](_cTokens.length);

        for (uint256 i = 0; i < _cTokens.length; ++i) {
            supplyClaims[i] = getSuppyBalance(_cTokens[i], _user) > 0;
            borrowClaims[i] = getBorrowBalance(_cTokens[i], _user) > 0;
        }
    }

    function getSuppyBalance(address _cToken, address _supplier)
        public
        view
        returns (uint256 supplierAccrued)
    {
        ComptrollerInterface.CompMarketState memory supplyState = comp.compSupplyState(_cToken);
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({
            mantissa: comp.compSupplierIndex(_cToken, _supplier)
        });

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = compInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint256 supplierTokens = CTokenInterface(_cToken).balanceOf(_supplier);
        uint256 supplierDelta = mul_(supplierTokens, deltaIndex);
        supplierAccrued = supplierDelta;
    }

    function getBorrowBalance(address _cToken, address _borrower)
        public
        view
        returns (uint256 borrowerAccrued)
    {
        ComptrollerInterface.CompMarketState memory borrowState = comp.compBorrowState(_cToken);
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({
            mantissa: comp.compBorrowerIndex(_cToken, _borrower)
        });

        Exp memory marketBorrowIndex = Exp({mantissa: CTokenInterface(_cToken).borrowIndex()});

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint256 borrowerAmount = div_(
                CTokenInterface(_cToken).borrowBalanceStored(_borrower),
                marketBorrowIndex
            );
            uint256 borrowerDelta = mul_(borrowerAmount, deltaIndex);
            borrowerAccrued = borrowerDelta;
        }
    }
}
