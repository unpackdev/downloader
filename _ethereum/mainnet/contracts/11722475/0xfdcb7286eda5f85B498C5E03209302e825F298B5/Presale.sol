pragma solidity 0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./console.sol";

contract Presale {
    using SafeMath for uint256;

    // Properties of smart contract
    uint256 public presaleID = 0;

    struct TokenInfo {
        uint256 tokenPrice;
        uint256 tokenAmount;
        uint256 tokensSold;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address tokenAddress;
        address payable tokenOwner;
        bool hasEnded;
    }

    // mappings with index of presale id
    mapping(uint256 => TokenInfo) public tokenData;

    event NewPresale(uint256 newPresaleID, uint256 timestamp);

    // Start presale function
    function startPresale(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _tokenPrice,
        uint256 _tokenAmount,
        address _tokenAddress
    ) public {
        require(
            _startTimestamp < _endTimestamp,
            "Please ensure your end timestamp is greater than your start timestamp"
        );
        // change our _token property to the current token
        IERC20 token = IERC20(_tokenAddress);
        // transfer the current token to the presale contract
        uint balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        uint balanceAfter = token.balanceOf(address(this));
        uint actualTokenAmountReceived = balanceAfter.sub(balanceBefore);

        // create a new presale id and map it to the price, amount, start and end timestamps
        presaleID = presaleID + 1;
        uint256 newPresaleID = presaleID;

        tokenData[newPresaleID] = TokenInfo({
            tokenPrice: _tokenPrice,
            tokenAmount: actualTokenAmountReceived,
            tokensSold: 0,
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp,
            tokenAddress: _tokenAddress,
            tokenOwner: msg.sender,
            hasEnded: false
        });

        emit NewPresale(newPresaleID, block.timestamp);
    }

    // Buy function where customer enters presaleID and token amount to exchange eth for an ERC20 Token
    function buy(uint256 _presaleID, uint256 _tokenAmount) public payable {
        // make sure the presale has started but hasnt ended and the user is inputting enough ETH
        require(
            block.timestamp >= tokenData[_presaleID].startTimestamp,
            "This presale is still locked"
        );
        require(
            tokenData[_presaleID].hasEnded == false,
            "This presale has ended"
        );
        require(
            _tokenAmount <= tokenData[_presaleID].tokenAmount,
            "Not enough tokens to supply token amount requested"
        );
        require(
            msg.value >=
                tokenData[_presaleID].tokenPrice.mul(_tokenAmount).div(1 ether),
            "Not enough ETH to make purchase"
        );

        // transfer the tokens to the customer
        IERC20 token = IERC20(tokenData[_presaleID].tokenAddress);
        token.transfer(msg.sender, _tokenAmount);

        // update the amount of tokens that have been sold
        tokenData[_presaleID].tokensSold = tokenData[_presaleID].tokensSold.add(
            _tokenAmount
        );

        // decrease supply by the amount that is going to be sold
        tokenData[_presaleID].tokenAmount = tokenData[_presaleID]
            .tokenAmount
            .sub(_tokenAmount);
    }

    function endPresale(uint256 _presaleID) public {
        // ensure presale has ended
        require(
            block.timestamp >= tokenData[_presaleID].endTimestamp,
            "Presale has not ended yet"
        );
        // Can only end presale once
        require(
            tokenData[_presaleID].hasEnded == false,
            "This presale has already ended"
        );

        // Lock the presale by ending it
        tokenData[_presaleID].hasEnded = true;

        // Calculate net ETH recieved and figure out how much to give to the user and admin based on the basis points
        uint256 netEth =
            tokenData[_presaleID]
                .tokensSold
                .mul(tokenData[_presaleID].tokenPrice)
                .div(1 ether);

        // Give respective fee to the owner
        tokenData[_presaleID].tokenOwner.transfer(netEth);

        // get unsold tokens and transfer back to user
        uint256 amountLeft = tokenData[_presaleID].tokenAmount;

        IERC20 token = IERC20(tokenData[_presaleID].tokenAddress);
        token.transfer(tokenData[_presaleID].tokenOwner, amountLeft);
    }
}
