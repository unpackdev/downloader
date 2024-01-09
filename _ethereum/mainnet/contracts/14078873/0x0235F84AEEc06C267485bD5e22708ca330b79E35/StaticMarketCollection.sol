/*

  << Static Market contract >>

*/

pragma solidity 0.7.5;

import "./AuthenticatedProxy.sol";
import "./StaticCheckERC20.sol";
import "./StaticCheckERC721.sol";
import "./StaticAtomicizerBase.sol";

/**
 * @title StaticMarketCollection
 * @author Wyvern Protocol Developers
 */
contract StaticMarketCollection is StaticCheckERC20, StaticCheckERC721, StaticAtomicizerBase {

    string public constant name = "Static Market Collection";

    constructor (address addr)
        public
    {
        atomicizer = addr;
        owner = msg.sender;
    }

    function ERC20ForAnyERC721(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        require(uints[0] == 0, "ERC20ForAnyERC721: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC20ForAnyERC721: call must be a direct call");

        (address[2] memory tokenGiveGet, uint256[1] memory price) = abi.decode(extra, (address[2], uint256[1]));

        require(price[0] > 0,"ERC20ForAnyERC721: ERC721 price must be larger than zero");
        require(addresses[2] == tokenGiveGet[0], "ERC20ForAnyERC721: call target must equal address of token to give");
        require(addresses[5] == tokenGiveGet[1], "ERC20ForAnyERC721: countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata, addresses[4], addresses[1]);
        checkERC20Side(data, addresses[1], addresses[4], price[0]);

        return price[0];
    }

    function ERC20ForAnyERC721WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0, "ERC20ForAnyERC721WithOneFee: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ERC20ForAnyERC721WithOneFee: call must be a delegate call");

        (address[3] memory tokenGiveGetAndFeeRecipient, uint256[2] memory priceAndFee) = abi.decode(extra, (address[3], uint256[2]));

        require(priceAndFee[0] > 0,"ERC20ForAnyERC721WithOneFee: ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "ERC20ForAnyERC721WithOneFee: call target must equal address of atomicizer");
        require(addresses[5] == tokenGiveGetAndFeeRecipient[1], "ERC20ForAnyERC721WithOneFee: countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata, addresses[4], addresses[1]);
        checkERC20SideWithOneFee(data, addresses[1], addresses[4], tokenGiveGetAndFeeRecipient[2], priceAndFee[0], priceAndFee[1]);

        return priceAndFee[priceAndFee.length - 2] + priceAndFee[priceAndFee.length - 1];
    }

    function ERC20ForAnyERC721WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0, "ERC20ForAnyERC721WithTwoFees: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ERC20ForAnyERC721WithTwoFees: call must be a delegate call");

        (address[4] memory tokenGiveGetAndFeeRecipient, uint256[3] memory priceAndFee) = abi.decode(extra, (address[4], uint256[3]));

        require(priceAndFee[0] > 0, "ERC20ForAnyERC721WithTwoFees: ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "ERC20ForAnyERC721WithTwoFees: call target must equal address of atomicizer");
        require(addresses[5] == tokenGiveGetAndFeeRecipient[1], "ERC20ForAnyERC721WithTwoFees: countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata, addresses[4], addresses[1]);
        checkERC20SideWithTwoFees(data, addresses[1], addresses[4], tokenGiveGetAndFeeRecipient[2], tokenGiveGetAndFeeRecipient[3], priceAndFee[0], priceAndFee[1], priceAndFee[2]);

        return priceAndFee[priceAndFee.length - 3] + priceAndFee[priceAndFee.length - 2] + priceAndFee[priceAndFee.length - 1];
    }
}
