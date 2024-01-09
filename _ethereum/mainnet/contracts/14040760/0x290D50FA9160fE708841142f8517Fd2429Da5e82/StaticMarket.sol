/*

  << Static Market contract >>

*/

pragma solidity 0.7.5;

import "./AuthenticatedProxy.sol";
import "./StaticCheckERC20.sol";
import "./StaticCheckERC1155.sol";
import "./StaticCheckERC721.sol";
import "./StaticAtomicizerBase.sol";

/**
 * @title StaticMarket
 * @author Wyvern Protocol Developers
 */
contract StaticMarket is StaticCheckERC20, StaticCheckERC1155, StaticCheckERC721, StaticAtomicizerBase {

	string public constant name = "Static Market";

	constructor (address addr)
		public
	{
		atomicizer = addr;
		owner = msg.sender;
	}

	function anyERC1155ForERC20(bytes memory extra,
		address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
		bytes memory data, bytes memory counterdata)
		public
		pure
		returns (uint)
	{
		require(uints[0] == 0,"anyERC1155ForERC20: Zero value required");
		require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "anyERC1155ForERC20: call must be a direct call");

		(address[2] memory tokenGiveGet, uint256[3] memory tokenIdAndNumeratorDenominator) = abi.decode(extra, (address[2], uint256[3]));

		require(tokenIdAndNumeratorDenominator[1] > 0,"anyERC1155ForERC20: numerator must be larger than zero");
		require(tokenIdAndNumeratorDenominator[2] > 0,"anyERC1155ForERC20: denominator must be larger than zero");
		require(addresses[2] == tokenGiveGet[0], "anyERC1155ForERC20: call target must equal address of token to give");
		require(addresses[5] == tokenGiveGet[1], "anyERC1155ForERC20: countercall target must equal address of token to get");

		uint256[2] memory call_amounts = [
			getERC1155AmountFromCalldata(data),
			getERC20AmountFromCalldata(counterdata)
		];
		uint256 new_fill = SafeMath.add(uints[5],call_amounts[0]);
		require(new_fill <= uints[1],"anyERC1155ForERC20: new fill exceeds maximum fill");
        // call_amounts[1] erc20 amount / call_amounts[0] erc1155 amount = price per 1155
        // tokenIdAndNumeratorDenominator[2] total sell price / tokenIdAndNumeratorDenominator[1] total 1155 amount = price per 1155
        // so call_amounts[1] erc20 amount / call_amounts[0] = tokenIdAndNumeratorDenominator[2] total sell price / tokenIdAndNumeratorDenominator[1]
        // change the equation to tokenIdAndNumeratorDenominator[1] * call_amounts[1] = tokenIdAndNumeratorDenominator[2] * call_amounts[0]
		require(SafeMath.mul(tokenIdAndNumeratorDenominator[1], call_amounts[1]) == SafeMath.mul(tokenIdAndNumeratorDenominator[2], call_amounts[0]),"anyERC1155ForERC20: wrong ratio");
		checkERC1155Side(data,addresses[1],addresses[4],tokenIdAndNumeratorDenominator[0],call_amounts[0]);
		checkERC20Side(counterdata,addresses[4],addresses[1],call_amounts[1]);

		return new_fill;
	}

	function anyERC20ForERC1155(bytes memory extra,
		address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
		bytes memory data, bytes memory counterdata)
		public
		pure
		returns (uint)
	{
		require(uints[0] == 0,"anyERC20ForERC1155: Zero value required");
		require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "anyERC20ForERC1155: call must be a direct call");

		(address[2] memory tokenGiveGet, uint256[3] memory tokenIdAndNumeratorDenominator) = abi.decode(extra, (address[2], uint256[3]));

		require(tokenIdAndNumeratorDenominator[1] > 0,"anyERC20ForERC1155: numerator must be larger than zero");
		require(tokenIdAndNumeratorDenominator[2] > 0,"anyERC20ForERC1155: denominator must be larger than zero");
		require(addresses[2] == tokenGiveGet[0], "anyERC20ForERC1155: call target must equal address of token to get");
		require(addresses[5] == tokenGiveGet[1], "anyERC20ForERC1155: countercall target must equal address of token to give");

		uint256[2] memory call_amounts = [
			getERC1155AmountFromCalldata(counterdata),
			getERC20AmountFromCalldata(data)
		];
		uint256 new_fill = SafeMath.add(uints[5],call_amounts[1]);
		require(new_fill <= uints[1],"anyERC20ForERC1155: new fill exceeds maximum fill");
        // call_amounts[1] erc20 amount / call_amounts[0] erc1155 amount = price per 1155
        // tokenIdAndNumeratorDenominator[1] total buy price / tokenIdAndNumeratorDenominator[2] total 1155 amount = price per 1155
        // so call_amounts[1] erc20 amount / call_amounts[0] = tokenIdAndNumeratorDenominator[1] total sell price / tokenIdAndNumeratorDenominator[2]
        // change the equation to tokenIdAndNumeratorDenominator[1] * call_amounts[0] = tokenIdAndNumeratorDenominator[2] * call_amounts[1]
		require(SafeMath.mul(tokenIdAndNumeratorDenominator[1], call_amounts[0]) == SafeMath.mul(tokenIdAndNumeratorDenominator[2], call_amounts[1]),"anyERC20ForERC1155: wrong ratio");
		checkERC1155Side(counterdata,addresses[4],addresses[1],tokenIdAndNumeratorDenominator[0],call_amounts[0]);
		checkERC20Side(data,addresses[1],addresses[4],call_amounts[1]);

		return new_fill;
	}

    function anyERC20ForERC1155WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"anyERC20ForERC1155WithOneFee: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "anyERC20ForERC1155WithOneFee: call must be a delegate call");

        (address[3] memory tokenGiveGetAndFeeRecipient, uint256[4] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[3], uint256[4]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0,"anyERC20ForERC1155WithOneFee: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0,"anyERC20ForERC1155WithOneFee: denominator must be larger than zero");

        require(addresses[2] == atomicizer, "anyERC20ForERC1155WithOneFee: call target must equal address of atomicizer");
        require(addresses[5] == tokenGiveGetAndFeeRecipient[1], "anyERC20ForERC1155WithOneFee: countercall target must equal address of token to give");

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(counterdata),
            getERC20AmountFromCalldataWithOneFee(data)
        ];
        uint256 new_fill = 0;
        uint256 fee = tokenIdAndNumeratorDenominatorAndFee[3];
        {
            new_fill = SafeMath.add(SafeMath.add(uints[5],call_amounts[1]), fee);
            require(new_fill <= uints[1],"anyERC20ForERC1155WithOneFee: new fill exceeds maximum fill");
            // (call_amounts[1] erc20 amount + fee) / call_amounts[0] erc1155 amount = price per 1155
            // (tokenIdAndNumeratorDenominator[1] total buy price + fee) / tokenIdAndNumeratorDenominator[2] total 1155 amount = price per 1155
            // (call_amounts[1] erc20 amount + fee) / call_amounts[0] = (tokenIdAndNumeratorDenominator[1] total buy price + fee)  / tokenIdAndNumeratorDenominator[2]
            // change the equation to (tokenIdAndNumeratorDenominator[1] total buy price + fee) * call_amounts[0] = tokenIdAndNumeratorDenominator[2] * (call_amounts[1] erc20 amount + fee)
            require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1] + fee, call_amounts[0]) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2], call_amounts[1] + fee),"anyERC20ForERC1155WithOneFee: wrong ratio");
        }
        checkERC1155Side(counterdata,addresses[4],addresses[1],tokenIdAndNumeratorDenominatorAndFee[0],call_amounts[0]);
        checkERC20SideWithOneFee(data, addresses[1], addresses[4], tokenGiveGetAndFeeRecipient[2], call_amounts[1], fee);

        return new_fill;
    }

    function anyERC20ForERC1155WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"anyERC20ForERC1155WithTwoFees: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "anyERC20ForERC1155WithTwoFees: call must be a delegate call");

        (address[4] memory tokenGiveGetAndFeeRecipient, uint256[5] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[4], uint256[5]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0,"anyERC20ForERC1155WithTwoFees: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0,"anyERC20ForERC1155WithTwoFees: denominator must be larger than zero");

        require(addresses[2] == atomicizer, "anyERC20ForERC1155WithTwoFees: call target must equal address of atomicizer");
        require(addresses[5] == tokenGiveGetAndFeeRecipient[1], "anyERC20ForERC1155WithTwoFees: countercall target must equal address of token to give");

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(counterdata),
            getERC20AmountFromCalldataWithTwoFees(data)
        ];
        uint256 new_fill = 0;
        uint256 fee = tokenIdAndNumeratorDenominatorAndFee[3];
        uint256 royaltyFee = tokenIdAndNumeratorDenominatorAndFee[4];
        {
            new_fill = SafeMath.add(SafeMath.add(SafeMath.add(uints[5],call_amounts[1]), fee), royaltyFee);
            require(new_fill <= uints[1],"anyERC20ForERC1155WithTwoFees: new fill exceeds maximum fill");
            // (call_amounts[1] erc20 amount + fee + royalty) / call_amounts[0] erc1155 amount = price per 1155
            // (tokenIdAndNumeratorDenominator[1] total buy price + fee + royalty) / tokenIdAndNumeratorDenominator[2] total 1155 amount = price per 1155
            // (call_amounts[1] erc20 amount + fee + royalty) / call_amounts[0] = (tokenIdAndNumeratorDenominator[1] total buy price + fee + royalty)  / tokenIdAndNumeratorDenominator[2]
            // change the equation to (tokenIdAndNumeratorDenominator[1] total buy price + fee + royalty) * call_amounts[0] = tokenIdAndNumeratorDenominator[2] * (call_amounts[1] erc20 amount + fee + royalty)
            require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1] + fee + royaltyFee, call_amounts[0]) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2], call_amounts[1] + fee + royaltyFee),"anyERC20ForERC1155WithTwoFees: wrong ratio");
        }
        checkERC1155Side(counterdata,addresses[4],addresses[1],tokenIdAndNumeratorDenominatorAndFee[0],call_amounts[0]);
        checkERC20SideWithTwoFees(data, addresses[1], addresses[4], tokenGiveGetAndFeeRecipient[2], tokenGiveGetAndFeeRecipient[3], call_amounts[1], fee, royaltyFee);

        return new_fill;
    }

    function anyERC1155ForERC20WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"anyERC1155ForERC20WithOneFee: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "anyERC1155ForERC20WithOneFee: call must be a direct call");

        (address[3] memory tokenGiveGetAndFeeRecipient, uint256[4] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[3], uint256[4]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0,"anyERC1155ForERC20WithOneFee: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0,"anyERC1155ForERC20WithOneFee: denominator must be larger than zero");
        require(addresses[2] == tokenGiveGetAndFeeRecipient[0], "anyERC1155ForERC20WithOneFee: call target must equal address of token to give");
        require(addresses[5] == atomicizer, "anyERC1155ForERC20WithOneFee: countercall target must equal address of atomicizer");

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(data),
            getERC20AmountFromCalldataWithOneFee(counterdata)
        ];
        uint256 new_fill = 0;
        uint256 fee = tokenIdAndNumeratorDenominatorAndFee[3];
        {
            new_fill = SafeMath.add(uints[5],call_amounts[0]);
            require(new_fill <= uints[1],"anyERC1155ForERC20WithOneFee: new fill exceeds maximum fill");
            // (call_amounts[1] erc20 amount + fee) / call_amounts[0] erc1155 amount = price per 1155
            // (tokenIdAndNumeratorDenominator[2] total sell price + fee) / tokenIdAndNumeratorDenominator[1] total 1155 amount = price per 1155
            // so (call_amounts[1] erc20 amount + fee) / call_amounts[0] = (tokenIdAndNumeratorDenominator[2] total sell price + fee) / tokenIdAndNumeratorDenominator[1]
            // change the equation to tokenIdAndNumeratorDenominator[1] * (call_amounts[1] erc20 amount + fee)  = (tokenIdAndNumeratorDenominator[2] total sell price + fee) * call_amounts[0]
            require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1], call_amounts[1] + fee) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2] + fee, call_amounts[0]),"anyERC1155ForERC20WithOneFee: wrong ratio");
        }

        checkERC1155Side(data,addresses[1],addresses[4],tokenIdAndNumeratorDenominatorAndFee[0],call_amounts[0]);
        checkERC20SideWithOneFee(counterdata, addresses[4], addresses[1], tokenGiveGetAndFeeRecipient[2], call_amounts[1], fee);

        return new_fill;
    }

    function anyERC1155ForERC20WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"anyERC1155ForERC20WithTwoFees: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "anyERC1155ForERC20WithTwoFees: call must be a direct call");

        (address[4] memory tokenGiveGetAndFeeRecipient, uint256[5] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[4], uint256[5]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0,"anyERC1155ForERC20WithTwoFees: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0,"anyERC1155ForERC20WithTwoFees: denominator must be larger than zero");
        require(addresses[2] == tokenGiveGetAndFeeRecipient[0], "anyERC1155ForERC20WithTwoFees: call target must equal address of token to give");
        require(addresses[5] == atomicizer, "anyERC1155ForERC20WithTwoFees: countercall target must equal address of atomicizer");

        uint256[2] memory call_amounts = [
            getERC1155AmountFromCalldata(data),
            getERC20AmountFromCalldataWithTwoFees(counterdata)
        ];
        uint256 new_fill = 0;
        uint256 fee = tokenIdAndNumeratorDenominatorAndFee[3];
        uint256 royaltyFee = tokenIdAndNumeratorDenominatorAndFee[4];
        {
            new_fill = SafeMath.add(uints[5],call_amounts[0]);
            require(new_fill <= uints[1],"anyERC1155ForERC20WithTwoFees: new fill exceeds maximum fill");
            // (call_amounts[1] erc20 amount + fee + royalty) / call_amounts[0] erc1155 amount = price per 1155
            // (tokenIdAndNumeratorDenominator[2] total sell price + fee + royalty) / tokenIdAndNumeratorDenominator[1] total 1155 amount = price per 1155
            // so (call_amounts[1] erc20 amount + fee + royalty) / call_amounts[0] = (tokenIdAndNumeratorDenominator[2] total sell price + fee + royalty) / tokenIdAndNumeratorDenominator[1]
            // change the equation to tokenIdAndNumeratorDenominator[1] * (call_amounts[1] erc20 amount + fee + royalty)  = (tokenIdAndNumeratorDenominator[2] total sell price + fee + royalty) * call_amounts[0]
            require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1], call_amounts[1] + fee + royaltyFee) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2] + fee + royaltyFee, call_amounts[0]),"anyERC1155ForERC20WithTwoFees: wrong ratio");
        }

        checkERC1155Side(data,addresses[1],addresses[4],tokenIdAndNumeratorDenominatorAndFee[0],call_amounts[0]);
        checkERC20SideWithTwoFees(counterdata, addresses[4], addresses[1], tokenGiveGetAndFeeRecipient[2], tokenGiveGetAndFeeRecipient[3], call_amounts[1], fee, royaltyFee);

        return new_fill;
    }

	function anyERC20ForERC20(bytes memory extra,
		address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
		bytes memory data, bytes memory counterdata)
		public
		pure
		returns (uint)
	{
		require(uints[0] == 0,"anyERC20ForERC20: Zero value required");
		require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "anyERC20ForERC20: call must be a direct call");

		(address[2] memory tokenGiveGet, uint256[2] memory numeratorDenominator) = abi.decode(extra, (address[2], uint256[2]));

		require(numeratorDenominator[0] > 0,"anyERC20ForERC20: numerator must be larger than zero");
		require(numeratorDenominator[1] > 0,"anyERC20ForERC20: denominator must be larger than zero");
		require(addresses[2] == tokenGiveGet[0], "anyERC20ForERC20: call target must equal address of token to give");
		require(addresses[5] == tokenGiveGet[1], "anyERC20ForERC20: countercall target must equal address of token to get");

		uint256[2] memory call_amounts = [
			getERC20AmountFromCalldata(data),
			getERC20AmountFromCalldata(counterdata)
		];
		uint256 new_fill = SafeMath.add(uints[5],call_amounts[0]);
		require(new_fill <= uints[1],"anyERC20ForERC20: new fill exceeds maximum fill");
		require(SafeMath.mul(numeratorDenominator[0],call_amounts[0]) == SafeMath.mul(numeratorDenominator[1],call_amounts[1]),"anyERC20ForERC20: wrong ratio");
		checkERC20Side(data,addresses[1],addresses[4],call_amounts[0]);
		checkERC20Side(counterdata,addresses[4],addresses[1],call_amounts[1]);

		return new_fill;
	}

	function ERC721ForERC20(bytes memory extra,
		address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
		bytes memory data, bytes memory counterdata)
		public
		pure
		returns (uint)
	{
		require(uints[0] == 0,"ERC721ForERC20: Zero value required");
		require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721ForERC20: call must be a direct call");

		(address[2] memory tokenGiveGet, uint256[2] memory tokenIdAndPrice) = abi.decode(extra, (address[2], uint256[2]));

		require(tokenIdAndPrice[1] > 0,"ERC721ForERC20: ERC721 price must be larger than zero");
		require(addresses[2] == tokenGiveGet[0], "ERC721ForERC20: call target must equal address of token to give");
		require(addresses[5] == tokenGiveGet[1], "ERC721ForERC20: countercall target must equal address of token to get");

		checkERC721Side(data,addresses[1],addresses[4],tokenIdAndPrice[0]);
		checkERC20Side(counterdata,addresses[4],addresses[1],tokenIdAndPrice[1]);

		return 1;
	}

	function ERC20ForERC721(bytes memory extra,
		address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
		bytes memory data, bytes memory counterdata)
		public
		pure
		returns (uint)
	{
		require(uints[0] == 0,"ERC20ForERC721: Zero value required");
		require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC20ForERC721: call must be a direct call");

		(address[2] memory tokenGiveGet, uint256[2] memory tokenIdAndPrice) = abi.decode(extra, (address[2], uint256[2]));

		require(tokenIdAndPrice[1] > 0,"ERC20ForERC721: ERC721 price must be larger than zero");
		require(addresses[2] == tokenGiveGet[0], "ERC20ForERC721: call target must equal address of token to give");
		require(addresses[5] == tokenGiveGet[1], "ERC20ForERC721: countercall target must equal address of token to get");

		checkERC721Side(counterdata,addresses[4],addresses[1],tokenIdAndPrice[0]);
		checkERC20Side(data,addresses[1],addresses[4],tokenIdAndPrice[1]);

		return tokenIdAndPrice[1];
	}

    function ERC721ForERC20WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"ERC721ForERC20WithOneFee: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721ForERC20WithOneFee: call must be a direct call");

        (address[3] memory tokenGiveGetAndFeeRecipient, uint256[3] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[3], uint256[3]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721ForERC20WithOneFee: ERC721 price must be larger than zero");
        require(addresses[2] == tokenGiveGetAndFeeRecipient[0], "ERC721ForERC20WithOneFee: call target must equal address of token to give");
        require(addresses[5] == atomicizer, "ERC721ForERC20WithOneFee: countercall target must equal address of atomicizer");

        checkERC721Side(data,addresses[1],addresses[4],tokenIdAndPriceAndFee[0]);
        checkERC20SideWithOneFee(counterdata,addresses[4],addresses[1],tokenGiveGetAndFeeRecipient[2],tokenIdAndPriceAndFee[1],tokenIdAndPriceAndFee[2]);

        return 1;
    }

    function ERC721ForERC20WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"ERC721ForERC20WithTwoFees: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721ForERC20WithTwoFees: call must be a direct call");

        (address[4] memory tokenGiveGetAndFeeRecipient, uint256[4] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[4], uint256[4]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721ForERC20WithTwoFees: ERC721 price must be larger than zero");
        require(addresses[2] == tokenGiveGetAndFeeRecipient[0], "ERC721ForERC20WithTwoFees: call target must equal address of token to give");
        require(addresses[5] == atomicizer, "ERC721ForERC20WithTwoFees: countercall target must equal address of atomicizer");

        checkERC721Side(data,addresses[1],addresses[4],tokenIdAndPriceAndFee[0]);
        checkERC20SideWithTwoFees(counterdata,addresses[4],addresses[1],tokenGiveGetAndFeeRecipient[2],tokenGiveGetAndFeeRecipient[3],tokenIdAndPriceAndFee[1],tokenIdAndPriceAndFee[2],tokenIdAndPriceAndFee[3]);

        return 1;
    }

    function ERC20ForERC721WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"ERC20ForERC721WithOneFee: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ERC20ForERC721WithFee: call must be a delegate call");

        (address[3] memory tokenGiveGetAndFeeRecipient, uint256[3] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[3], uint256[3]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC20ForERC721WithOneFee: ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "ERC20ForERC721WithOneFee: call target must equal address of atomicizer");
        require(addresses[5] == tokenGiveGetAndFeeRecipient[1], "ERC20ForERC721WithOneFee: countercall target must equal address of token to get");

        checkERC721Side(counterdata,addresses[4],addresses[1],tokenIdAndPriceAndFee[0]);
        checkERC20SideWithOneFee(data,addresses[1],addresses[4],tokenGiveGetAndFeeRecipient[2],tokenIdAndPriceAndFee[1],tokenIdAndPriceAndFee[2]);

        return tokenIdAndPriceAndFee[1] + tokenIdAndPriceAndFee[2];
    }

    function ERC20ForERC721WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        view
        returns (uint)
    {
        require(uints[0] == 0,"ERC20ForERC721WithTwoFees: Zero value required");
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ERC20ForERC721WithTwoFees: call must be a delegate call");

        (address[4] memory tokenGiveGetAndFeeRecipient, uint256[4] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[4], uint256[4]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC20ForERC721WithTwoFees: ERC721 price must be larger than zero");
        require(addresses[2] == atomicizer, "ERC20ForERC721WithTwoFees: call target must equal address of atomicizer");
        require(addresses[5] == tokenGiveGetAndFeeRecipient[1], "ERC20ForERC721WithTwoFees: countercall target must equal address of token to get");

        checkERC721Side(counterdata,addresses[4],addresses[1],tokenIdAndPriceAndFee[0]);
        checkERC20SideWithTwoFees(data,addresses[1],addresses[4],tokenGiveGetAndFeeRecipient[2],tokenGiveGetAndFeeRecipient[3],tokenIdAndPriceAndFee[1],tokenIdAndPriceAndFee[2],tokenIdAndPriceAndFee[3]);

        return tokenIdAndPriceAndFee[1] + tokenIdAndPriceAndFee[2] + tokenIdAndPriceAndFee[3];
    }

	function getERC20AmountFromCalldata(bytes memory data)
		internal
		pure
		returns (uint256)
	{
		(uint256 amount) = abi.decode(ArrayUtils.arraySlice(data,68,32),(uint256));
		return amount;
	}

    function getERC20AmountFromCalldataWithOneFee(bytes memory data)
        internal
        pure
        returns (uint256 amount)
    {
        (uint256 amount) = abi.decode(ArrayUtils.arraySlice(data,424,32),(uint256));
        return amount;
    }

    function getERC20AmountFromCalldataWithTwoFees(bytes memory data)
        internal
        pure
        returns (uint256 amount)
    {
        (uint256 amount) = abi.decode(ArrayUtils.arraySlice(data,520,32),(uint256));
        return amount;
    }
}
