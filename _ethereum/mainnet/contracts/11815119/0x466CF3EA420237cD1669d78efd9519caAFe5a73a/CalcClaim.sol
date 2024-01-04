pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Exponential.sol";
import "./Controller.sol";
import "./PToken.sol";

contract ClaimCalc is Exponential {
    Controller public controller;

    constructor(address _controller) {
        controller = Controller(_controller);
    }

    function allMarkets() public view returns (address[] memory) {
        return controller.getAllMarkets();
    }

    function getBlockNumber() public view returns (uint) {
        return controller.getBlockNumber() + 1;
    }

    function updatePieBorrowIndex(address pToken, Exp memory marketBorrowIndex) public view returns (Double memory) {
        (uint224 index, uint32 block) = controller.pieBorrowState(pToken);

        Double memory newBorrowindex = Double({mantissa: index});

        uint borrowSpeed = controller.pieSpeeds(pToken);
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(PTokenInterface(pToken).totalBorrows(), marketBorrowIndex);
            uint pieAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(pieAccrued, borrowAmount) : Double({mantissa: 0});
            newBorrowindex = add_(Double({mantissa: index}), ratio);
        }

        return newBorrowindex;
    }

    function updatePieSupplyIndex(address pToken)  public view returns (Double memory) {
        (uint224 index, uint32 block) = controller.pieSupplyState(pToken);

        Double memory newSupplyIndex = Double({mantissa: index});

        uint supplySpeed = controller.pieSpeeds(pToken);
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = PTokenInterface(pToken).totalSupply();
            uint pieAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(pieAccrued, supplyTokens) : Double({mantissa: 0});
            newSupplyIndex = add_(Double({mantissa: index}), ratio);
        }

        return newSupplyIndex;
    }

    function calcClaimPie(address holder) public view returns (uint) {
        return calcClaimPie(holder, controller.getAllMarkets());
    }

    function calcClaimPie(address holder, address[] memory pTokens) public view returns (uint) {
        uint claimAmount = calcClaimPieWithoutAccrued(holder, pTokens);

        uint accrued = controller.pieAccrued(holder);
        return claimAmount + accrued;
    }

    function calcClaimPieWithoutAccrued(address holder, address[] memory pTokens) public view returns (uint) {
        uint amount;

        for (uint i = 0; i < pTokens.length; i++) {
            address pToken = pTokens[i];

            Exp memory marketBorrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
            Double memory borrowIndex = updatePieBorrowIndex(pToken, marketBorrowIndex);

            Double memory borrowerIndex = Double({mantissa: controller.pieBorrowerIndex(pToken, holder)});

            if (borrowerIndex.mantissa > 0) {
                Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
                uint borrowerAmount = div_(PTokenInterface(pToken).borrowBalanceStored(holder), marketBorrowIndex);
                uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
                amount = add_(amount, borrowerDelta);
            }

            Double memory supplyIndex = updatePieSupplyIndex(pToken);

            Double memory supplierIndex = Double({mantissa:  controller.pieSupplierIndex(pToken, holder)});

            if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
                supplierIndex.mantissa =  controller.pieInitialIndex();
            }

            Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
            uint supplierTokens = PTokenInterface(pToken).balanceOf(holder);
            uint supplierDelta = mul_(supplierTokens, deltaIndex);
            amount = add_(amount, supplierDelta);
        }

        return amount;
    }

    function checkClaimPieMarkets(address holder) public view returns (address[] memory) {
        return checkClaimPieMarkets(holder, controller.getAllMarkets());
    }

    function checkClaimPieMarkets(address holder, address[] memory pTokens) public view returns (address[] memory) {
        address[] memory markets = new address[](pTokens.length);
        uint count;

        for (uint i = 0; i < pTokens.length; i++) {
            uint delta;

            Exp memory marketBorrowIndex = Exp({mantissa: PTokenInterface(pTokens[i]).borrowIndex()});
            Double memory index = updatePieBorrowIndex(pTokens[i], marketBorrowIndex);

            Double memory borrowerIndex = Double({mantissa: controller.pieBorrowerIndex(pTokens[i], holder)});

            if (borrowerIndex.mantissa > 0) {
                uint borrowerAmount = div_(PTokenInterface(pTokens[i]).borrowBalanceStored(holder), marketBorrowIndex);
                delta = mul_(borrowerAmount, sub_(index, borrowerIndex));
            }

            index = updatePieSupplyIndex(pTokens[i]);

            Double memory supplierIndex = Double({mantissa: controller.pieSupplierIndex(pTokens[i], holder)});

            if (supplierIndex.mantissa == 0 && index.mantissa > 0) {
                supplierIndex.mantissa =  controller.pieInitialIndex();
            }

            uint supplierTokens = PTokenInterface(pTokens[i]).balanceOf(holder);
            delta = delta + mul_(supplierTokens, sub_(index, supplierIndex));

            if (delta > 0) {
                markets[count] = pTokens[i];
                count++;
            }
        }

        address[] memory claimPieMarkets = new address[](count);

        for(uint i = 0; i < count; i++) {
            claimPieMarkets[i] = markets[i];
        }

        return claimPieMarkets;
    }
}