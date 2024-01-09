/*

  << Static Market contract >>

*/

import "./AuthenticatedProxy.sol";
import "./StaticCheckERC20.sol";
import "./StaticCheckERC721.sol";
import "./StaticCheckERC1155.sol";
import "./StaticCheckETH.sol";
import "./StaticAtomicizerBase.sol";

pragma solidity 0.7.5;

contract StaticMarketPlatform is StaticCheckERC20, StaticCheckERC721, StaticCheckERC1155, StaticCheckETH, StaticAtomicizerBase {
    constructor (address addr)
        public
    {
        atomicizer = addr;
        owner = msg.sender;
    }

    function ERC721ForETH(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "call must be a direct call");

        (address[1] memory tokenGive, uint256[2] memory tokenIdAndPrice) = abi.decode(extra, (address[1], uint256[2]));

        require(tokenIdAndPrice[1] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == tokenGive[0], "call target must equal address of token to give");
        require(addresses[5] == atomicizer, "countercall target must equal address of atomicizer");

        checkERC721Side(data,addresses[1],addresses[4],tokenIdAndPrice[0]);

        checkETHSideWithOffset(addresses[1], uints[0], tokenIdAndPrice[1], counterdata);

        return 1;
    }

    function ETHForERC721(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[1] memory tokenGet, uint256[2] memory tokenIdAndPrice) = abi.decode(extra, (address[1], uint256[2]));

        require(tokenIdAndPrice[1] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "call target must equal address of atomicizer");
        require(addresses[5] == tokenGet[0], "countercall target must equal address of token to get");

        checkERC721Side(counterdata,addresses[4],addresses[1],tokenIdAndPrice[0]);

        checkETHSideWithOffset(addresses[4], uints[0], tokenIdAndPrice[1], data);

        return tokenIdAndPrice[tokenIdAndPrice.length - 1];
    }

    function ERC721ForETHWithOneFee(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "call must be a direct call");

        (address[2] memory tokenGiveAndFeeRecipient, uint256[3] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[2], uint256[3]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == tokenGiveAndFeeRecipient[0], "call target must equal address of token to give");
        require(addresses[5] == atomicizer, "countercall target must equal address of atomicizer");

        checkERC721Side(data, addresses[1], addresses[4], tokenIdAndPriceAndFee[0]);

        checkETHSideOneFeeWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], counterdata);

        return 1;
    }

    function ETHForERC721WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[2] memory tokenGetAndFeeRecipient, uint256[3] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[2], uint256[3]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "call target must equal address of atomicizer");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "countercall target must equal address of token to get");

        checkERC721Side(counterdata, addresses[4], addresses[1], tokenIdAndPriceAndFee[0]);

        checkETHSideOneFeeWithOffset(addresses[4], tokenGetAndFeeRecipient[1], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], data);

        return tokenIdAndPriceAndFee[tokenIdAndPriceAndFee.length - 2] + tokenIdAndPriceAndFee[tokenIdAndPriceAndFee.length - 1];
    }

    function ERC721ForETHWithTwoFees(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "call must be a direct call");

        (address[3] memory tokenGiveAndFeeRecipient, uint256[4] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[3], uint256[4]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == tokenGiveAndFeeRecipient[0], "call target must equal address of token to give");
        require(addresses[5] == atomicizer, "countercall target must equal address of atomicizer");

        checkERC721Side(data, addresses[1], addresses[4], tokenIdAndPriceAndFee[0]);

        checkETHSideTwoFeesWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], tokenGiveAndFeeRecipient[2], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], tokenIdAndPriceAndFee[3], counterdata);

        return 1;
    }

    function ETHForERC721WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[3] memory tokenGetAndFeeRecipient, uint256[4] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[3], uint256[4]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "call target must equal address of atomicizer");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "countercall target must equal address of token to get");

        checkERC721Side(counterdata, addresses[4], addresses[1], tokenIdAndPriceAndFee[0]);

        checkETHSideTwoFeesWithOffset(addresses[4], tokenGetAndFeeRecipient[1], tokenGetAndFeeRecipient[2], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], tokenIdAndPriceAndFee[3], data);

        return tokenIdAndPriceAndFee[tokenIdAndPriceAndFee.length - 3] + tokenIdAndPriceAndFee[tokenIdAndPriceAndFee.length - 2] + tokenIdAndPriceAndFee[tokenIdAndPriceAndFee.length - 1];
    }

    function ETHForAnyERC721(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[1] memory tokenGet, uint256[1] memory price) = abi.decode(extra, (address[1], uint256[1]));

        require(price[0] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "call target must equal address of atomicizer");
        require(addresses[5] == tokenGet[0], "countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata,addresses[4],addresses[1]);

        checkETHSideWithOffset(addresses[4], uints[0], price[0], data);

        return price[0];
    }

    function ETHForAnyERC721WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[2] memory tokenGetAndFeeRecipient, uint256[2] memory priceAndFee) = abi.decode(extra, (address[2], uint256[2]));

        require(priceAndFee[0] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "countercall target must equal address of atomicizer");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata, addresses[4], addresses[1]);

        checkETHSideOneFeeWithOffset(addresses[4], tokenGetAndFeeRecipient[1], uints[0], priceAndFee[0], priceAndFee[1], data);

        return priceAndFee[priceAndFee.length - 2] + priceAndFee[priceAndFee.length - 1];
    }

    function ETHForAnyERC721WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[3] memory tokenGetAndFeeRecipient, uint256[3] memory priceAndFee) = abi.decode(extra, (address[3], uint256[3]));

        require(priceAndFee[0] > 0,"ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "countercall target must equal address of atomicizer");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata, addresses[4], addresses[1]);

        checkETHSideTwoFeesWithOffset(addresses[4], tokenGetAndFeeRecipient[1], tokenGetAndFeeRecipient[2], uints[0], priceAndFee[0], priceAndFee[1], priceAndFee[2], data);

        return priceAndFee[priceAndFee.length - 3] + priceAndFee[priceAndFee.length - 2] + priceAndFee[priceAndFee.length - 1];
    }

    function ERC1155ForETH(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "call must be a direct call");

        (address[1] memory tokenGive, uint256[3] memory tokenIdAndNumeratorDenominator) = abi.decode(extra, (address[1], uint256[3]));

        require(tokenIdAndNumeratorDenominator[1] > 0, "numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominator[2] > 0, "denominator must be larger than zero");

        require(addresses[2] == tokenGive[0], "call target must equal address of token to give");
        require(addresses[5] == atomicizer, "countercall target must equal address of atomicizer");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(data);
        uint256 new_fill = SafeMath.add(uints[5], erc1155Amount);
        require(new_fill <= uints[1],"new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominator[1], uints[0]) == SafeMath.mul(tokenIdAndNumeratorDenominator[2], erc1155Amount), "wrong ratio");

        checkERC1155Side(data, addresses[1], addresses[4], tokenIdAndNumeratorDenominator[0], erc1155Amount);

        checkETHSideWithOffset(addresses[1], uints[0], tokenIdAndNumeratorDenominator[2], counterdata);

        return new_fill;
    }

    function ETHForERC1155(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[1] memory tokenGet, uint256[3] memory tokenIdAndNumeratorDenominator) = abi.decode(extra, (address[1], uint256[3]));

        require(tokenIdAndNumeratorDenominator[1] > 0,"numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominator[2] > 0,"denominator must be larger than zero");

        require(addresses[2] == atomicizer, "call target must equal address of atomicizer");
        require(addresses[5] == tokenGet[0], "countercall target must equal address of token to give");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(counterdata);
        uint256 new_fill = SafeMath.add(uints[5], uints[0]);
        require(new_fill <= uints[1],"new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominator[1], erc1155Amount) == SafeMath.mul(tokenIdAndNumeratorDenominator[2], uints[0]), "wrong ratio");

        checkERC1155Side(counterdata, addresses[4], addresses[1], tokenIdAndNumeratorDenominator[0], erc1155Amount);

        checkETHSideWithOffset(addresses[4], uints[0], tokenIdAndNumeratorDenominator[1], data);

        return new_fill;
    }

    function ERC1155ForETHWithOneFee(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "call must be a direct call");

        (address[2] memory tokenGiveAndFeeRecipient, uint256[4] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[2], uint256[4]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "denominator must be larger than zero");

        require(addresses[2] == tokenGiveAndFeeRecipient[0], "call target must equal address of token to give");
        require(addresses[5] == atomicizer, "countercall target must equal address of atomicizer");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(data);
        uint256 new_fill = SafeMath.add(uints[5], erc1155Amount);
        require(new_fill <= uints[1],"new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1], uints[0]) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2] + tokenIdAndNumeratorDenominatorAndFee[3], erc1155Amount), "wrong ratio");

        checkERC1155Side(data, addresses[1], addresses[4], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideOneFeeWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], uints[0], tokenIdAndNumeratorDenominatorAndFee[2], tokenIdAndNumeratorDenominatorAndFee[3], counterdata);

        return new_fill;
    }

    function ETHForERC1155WithOneFee(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[2] memory tokenGetAndFeeRecipient, uint256[4] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[2], uint256[4]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "denominator must be larger than zero");

        require(addresses[2] == atomicizer, "call target must equal address of atomicizer");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "countercall target must equal address of token to get");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(counterdata);
        uint256 new_fill = SafeMath.add(uints[5], uints[0]);
        require(new_fill <= uints[1],"new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1] + tokenIdAndNumeratorDenominatorAndFee[3], erc1155Amount) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2], uints[0]), "wrong ratio");

        checkERC1155Side(counterdata, addresses[4], addresses[1], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideOneFeeWithOffset(addresses[4], tokenGetAndFeeRecipient[1], uints[0], tokenIdAndNumeratorDenominatorAndFee[1], tokenIdAndNumeratorDenominatorAndFee[3], data);

        return new_fill;
    }

    function ERC1155ForETHWithTwoFees(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "call must be a direct call");

        (address[3] memory tokenGiveAndFeeRecipient, uint256[5] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[3], uint256[5]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "denominator must be larger than zero");

        require(addresses[2] == tokenGiveAndFeeRecipient[0], "call target must equal address of token to give");
        require(addresses[5] == atomicizer, "countercall target must equal address of atomicizer");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(data);
        uint256 new_fill = SafeMath.add(uints[5], erc1155Amount);
        require(new_fill <= uints[1],"new fill exceeds maximum fill");
        uint256 totalAmount = tokenIdAndNumeratorDenominatorAndFee[2] + tokenIdAndNumeratorDenominatorAndFee[3] + tokenIdAndNumeratorDenominatorAndFee[4];
        require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1], uints[0]) == SafeMath.mul(totalAmount, erc1155Amount), "wrong ratio");

        checkERC1155Side(data, addresses[1], addresses[4], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideTwoFeesWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], tokenGiveAndFeeRecipient[2], uints[0], tokenIdAndNumeratorDenominatorAndFee[2], tokenIdAndNumeratorDenominatorAndFee[3], tokenIdAndNumeratorDenominatorAndFee[4], counterdata);

        return 1;
    }

    function ETHForERC1155WithTwoFees(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public view returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "call must be a delegate call");

        (address[3] memory tokenGetAndFeeRecipient, uint256[5] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[3], uint256[5]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "denominator must be larger than zero");

        require(addresses[2] == atomicizer, "call target must equal address of atomicizer");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "countercall target must equal address of token to get");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(counterdata);
        uint256 new_fill = SafeMath.add(uints[5], uints[0]);
        require(new_fill <= uints[1],"new fill exceeds maximum fill");
        uint totalAmount = tokenIdAndNumeratorDenominatorAndFee[1] + tokenIdAndNumeratorDenominatorAndFee[3] + tokenIdAndNumeratorDenominatorAndFee[4];
        require(SafeMath.mul(totalAmount, erc1155Amount) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2], uints[0]), "wrong ratio");

        checkERC1155Side(counterdata, addresses[4], addresses[1], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideTwoFeesWithOffset(addresses[4], tokenGetAndFeeRecipient[1], tokenGetAndFeeRecipient[2], uints[0], tokenIdAndNumeratorDenominatorAndFee[1], tokenIdAndNumeratorDenominatorAndFee[3], tokenIdAndNumeratorDenominatorAndFee[4], data);

        return new_fill;
    }
}
