// SPDX-License-Identifier: MIT

/*
Total token supply: 1,000,000,000

10% Reserve
10% Advisors
20% Team
15% Foundation
10% Private 3 sale
5% Public sale
10% Seed round
15% Private sale 1
5% Private sale 2
*/

pragma solidity 0.8.17;

import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

contract Imbrium is ERC20Capped, ERC20Burnable {
    uint256 public timeOfPublishing;

    uint256 private totalTokenSupply = 1000000000;

    uint256 public releasePeriod = 10000000;

    uint256 feeInPercentage = 5;

    uint public tokensPerSecond = totalTokenSupply / releasePeriod * (10 ** decimals());


    struct userShareObj {
        uint256 totalTokenShare;

        uint256 remainingTokenShare;

        uint256 timestampOfLastClaim;
    }

    mapping(address => userShareObj) public userShareMap;

    // Contributor addresses
    address private Reserve = 0x542795BDcbeD4Dc47b535Add84C3A446Fb370289;
    address private Advisors = 0x807518744D08e546aC68ba22974D6a397EB32F70;
    address private Team = 0x0c321556099B88bD46879E698c3d7985aa11C756;
    address private Foundation = 0xC55703263793355fB283ee69b4DF251466EBEC4D;
    address private PrivateSale3 = 0xd3Ab5294039254547Dc5f2FD7cbfdAb050A8c322;
    address private PublicSale = 0x89a4d7e563902045A175cda895B8D41a221332E4;
    address private SeedRound = 0xEE1617D25D90ed8251717b631bB041276B1A2B31;
    address private PrivateSale1 = 0xE683fAEb26c1ffB6feA5a65411f8CaB4cb284b0f;
    address private PrivateSale2 = 0x5798F06ec7797C57010d48C33b1D51E993690C03;

    constructor() ERC20("Imbrium", "IMB") ERC20Capped(totalTokenSupply * (10 ** decimals()))  {
        timeOfPublishing = block.timestamp;

        userShareMap[Reserve] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[Advisors] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[Team] = userShareObj(
            calculateTokenShareBasedOnPercentage(20, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(20, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[Foundation] = userShareObj(
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PrivateSale3] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PublicSale] = userShareObj(
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[SeedRound] = userShareObj(
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(10, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PrivateSale1] = userShareObj(
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(15, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );

        userShareMap[PrivateSale2] = userShareObj(
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            calculateTokenShareBasedOnPercentage(5, totalTokenSupply) * (10 ** decimals()),
            timeOfPublishing
        );
    }

    function _mint(address _beneficiary, uint256 _amount) internal virtual override(ERC20, ERC20Capped) {
        require(ERC20.totalSupply() + _amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(_beneficiary, _amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 amountToTransfer = amount;
        uint256 amountToBurn = calculateBurnableFee(amount);

        amountToTransfer = amount - amountToBurn;
        burn(amountToBurn);

        super._transfer(from, to, amountToTransfer);
    }

    function calculateBurnableFee(uint256 amount) private view returns (uint256) {
        return amount * feeInPercentage / 100;
    }

    function calculateTokenShareBasedOnPercentage(uint256 _percentageToBeAwarded, uint256 _tokens) private pure returns(uint256) {
        return _tokens * _percentageToBeAwarded / 100;
    }

    function claimTokens() public {
        uint256 currentTime = block.timestamp;
        uint256 tokensToBeMinted;

        // TODO use modifier instead of if/else
        if (msg.sender == Reserve && userShareMap[Reserve].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Reserve, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Reserve, userShareMap, currentTime);
        } else if(msg.sender == Advisors && userShareMap[Advisors].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Advisors, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Advisors, userShareMap, currentTime);
        } else if(msg.sender == Team && userShareMap[Team].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Team, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Team, userShareMap, currentTime);
        } else if(msg.sender == Foundation && userShareMap[Foundation].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, Foundation, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, Foundation, userShareMap, currentTime);
        } else if(msg.sender == PrivateSale3 && userShareMap[PrivateSale3].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PrivateSale3, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PrivateSale3, userShareMap, currentTime);
        } else if(msg.sender == PublicSale && userShareMap[PublicSale].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PublicSale, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PublicSale, userShareMap, currentTime);
        } else if(msg.sender == SeedRound && userShareMap[SeedRound].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, SeedRound, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, SeedRound, userShareMap, currentTime);
        } else if(msg.sender == PrivateSale1 && userShareMap[PrivateSale1].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PrivateSale1, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PrivateSale1, userShareMap, currentTime);
        } else if(msg.sender == PrivateSale2 && userShareMap[PrivateSale2].remainingTokenShare > 0) {
            tokensToBeMinted = calculateTokensToBeReleased(userShareMap, PrivateSale2, currentTime);
            mintTokensAndDecrementTokensToBeMinted(tokensToBeMinted, PrivateSale2, userShareMap, currentTime);
        } else {
            require(false, "You are not authorized to claim tokens!");
        }
    }

    function calculateTokensToBeReleased(mapping(address => userShareObj) storage _userShareMap, address _beneficiary, uint256 _currentTime) private view returns(uint256) {
        // if all tokens are unlocked, return all remaining tokens for minting
        if (_currentTime > timeOfPublishing + releasePeriod) {
            return _userShareMap[_beneficiary].remainingTokenShare;
        } else {
            uint256 elapsedTimeSinceLastRelease = _currentTime - _userShareMap[_beneficiary].timestampOfLastClaim;
            uint256 tokens = elapsedTimeSinceLastRelease * tokensPerSecond;

            if (tokens < _userShareMap[_beneficiary].remainingTokenShare) {
                return tokens;
            } else {
                return _userShareMap[_beneficiary].remainingTokenShare;
            }
        }
    }

    function mintTokensAndDecrementTokensToBeMinted(uint256 _tokens, address _beneficiary, mapping(address => userShareObj) storage _userShareMap, uint256 _currentTime) private {
        _mint(_beneficiary, _tokens);

        uint256 decrementedTokens = _userShareMap[_beneficiary].remainingTokenShare - _tokens;
        _userShareMap[_beneficiary].remainingTokenShare = decrementedTokens;
        _userShareMap[_beneficiary].timestampOfLastClaim = _currentTime;

    }

}