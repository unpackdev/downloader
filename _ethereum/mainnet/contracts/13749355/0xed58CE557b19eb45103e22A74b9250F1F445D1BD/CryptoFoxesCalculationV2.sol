// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICryptoFoxesOrigins.sol";
import "./ICryptoFoxesStakingV2.sol";
import "./ICryptoFoxesCalculationOrigin.sol";
import "./ICryptoFoxesCalculationV2.sol";
import "./ICryptoFoxesStakingStruct.sol";
import "./IERC721.sol";
import "./CryptoFoxesUtility.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// @author: miinded.com

contract CryptoFoxesCalculationV2 is Ownable, ICryptoFoxesCalculationV2, ICryptoFoxesStakingStruct, ICryptoFoxesCalculationOrigin, CryptoFoxesUtility, ReentrancyGuard {
    uint256 public constant BASE_RATE_ORIGIN = 6 * 10**18;
    uint256 public constant BASE_RATE_V2 = 1 * 10**18;
    uint256 public BONUS_MAX_OWNED = 2; // 0.2

    address public cryptoFoxesOrigin;
    address public cryptoFoxesStakingV2;

    function setCryptoFoxesOrigin(address _contract) public onlyOwner{
        if(cryptoFoxesOrigin != address(0)) {
            setAllowedContract(cryptoFoxesOrigin, false);
        }
        setAllowedContract(_contract, true);
        cryptoFoxesOrigin = _contract;
    }

    function setCryptoFoxesStakingV2(address _contract) public onlyOwner{
        if(cryptoFoxesStakingV2 != address(0)) {
            setAllowedContract(cryptoFoxesStakingV2, false);
        }
        setAllowedContract(_contract, true);
        cryptoFoxesStakingV2 = _contract;
    }

    function calculationRewards(address _contract, uint256[] memory _tokenIds, uint256 _currentTimestamp) public override view returns(uint256){

        if(_tokenIds.length <= 0){ return 0; }

        address ownerOrigin = IERC721(_contract).ownerOf(_tokenIds[0]);
        uint256 _currentTime = ICryptoFoxesOrigins(_contract)._currentTime(_currentTimestamp);

        uint256 totalRewards = 0;

        unchecked {
            for (uint8 i = 0; i < _tokenIds.length; i++) {
                if(_tokenIds[i] > 1000) continue;
                for (uint8 j = 0; j < i; j++) {
                    require(_tokenIds[j] != _tokenIds[i], "Duplicate id");
                }

                uint256 stackTime = ICryptoFoxesOrigins(_contract).getStackingToken(_tokenIds[i]);
                stackTime = stackTime == 0 ? block.timestamp - 5 days : stackTime;
                if (_currentTime > stackTime) {
                    totalRewards += (_currentTime - stackTime) * BASE_RATE_ORIGIN;
                }

                // calcul des V2
                uint8 maxSlotsOrigin = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getOriginMaxSlot(uint16(_tokenIds[i]));
                Staking[] memory foxesV2 = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getV2ByOrigin(uint16(_tokenIds[i]));
                uint256 numberTokensOwner = 0;
                uint256 calculation = 0;
                for(uint8 k = 0; k < foxesV2.length; k++){
                    // calcul
                    calculation += (_currentTime - max(stackTime, foxesV2[k].timestampV2) ) * BASE_RATE_V2;

                    if(ownerOrigin == foxesV2[k].owner){
                        numberTokensOwner += 1;
                    }
                }

                totalRewards += calculation;

                if(numberTokensOwner == foxesV2.length && numberTokensOwner == maxSlotsOrigin){
                    totalRewards += calculation * BONUS_MAX_OWNED / 10;
                }
            }
        }

        return totalRewards / 86400;
    }

    function claimRewards(address _contract, uint256[] memory _tokenIds, address _owner) public override isFoxContract nonReentrant {
        require(!isPaused(), "Contract paused");

        uint256 reward = calculationRewards(_contract, _tokenIds, block.timestamp);
        _addRewards(_owner, reward);
        _withdrawRewards(_owner);
    }

    function calculationRewardsV2(address _contract, uint16[] memory _tokenIds, uint256 _currentTimestamp) public override view returns(uint256){
        uint256 _currentTime = ICryptoFoxesStakingV2(_contract)._currentTime(_currentTimestamp);
        uint256 totalSeconds = 0;
        unchecked {
            for (uint8 i = 0; i < _tokenIds.length; i++) {

                for (uint16 j = 0; j < i; j++) {
                    require(_tokenIds[j] != _tokenIds[i], "Duplicate id");
                }

                uint256 stackTime = ICryptoFoxesStakingV2(_contract).getStakingTokenV2(_tokenIds[i]);

                if (_currentTime > stackTime) {
                    totalSeconds += _currentTime - stackTime;
                }
            }
        }

        return (BASE_RATE_V2 * totalSeconds) / 86400;
    }

    function claimRewardsV2(address _contract, uint16[] memory _tokenIds, address _owner) public override isFoxContract nonReentrant {
        require(!isPaused(), "Contract paused");

        uint256 rewardV2 = 0;
        uint256 _currentTime = ICryptoFoxesStakingV2(_contract)._currentTime(block.timestamp);

        unchecked {
            for (uint8 i = 0; i < _tokenIds.length; i++) {

                uint256 stackTimeV2 = ICryptoFoxesStakingV2(_contract).getStakingTokenV2(_tokenIds[i]);

                uint16 origin = ICryptoFoxesStakingV2(_contract).getOriginByV2( _tokenIds[i] );
                uint256 stackTimeOrigin = ICryptoFoxesOrigins(cryptoFoxesOrigin).getStackingToken(origin);
                address ownerOrigin = IERC721(cryptoFoxesOrigin).ownerOf( origin );

                if (_currentTime > stackTimeV2) {
                    rewardV2 += (BASE_RATE_V2 * (_currentTime - stackTimeV2)) / 86400;
                    _addRewards(ownerOrigin, (BASE_RATE_V2 * (_currentTime - max(stackTimeOrigin, stackTimeV2) )) / 86400);
                }
            }
        }

        _addRewards(_owner, rewardV2);
        _withdrawRewards(_owner);
    }

    function claimMoveRewardsOrigin(address _contract, uint16 _tokenId, address _ownerOrigin) public override isFoxContract nonReentrant {
        uint256 _currentTime = ICryptoFoxesStakingV2(_contract)._currentTime(block.timestamp);

        uint16 origin = ICryptoFoxesStakingV2(_contract).getOriginByV2( _tokenId );
        Staking memory foxesV2 = ICryptoFoxesStakingV2(_contract).getFoxesV2( _tokenId );
        uint256 stackTimeOrigin = ICryptoFoxesOrigins(cryptoFoxesOrigin).getStackingToken(origin);
        uint256 stackTimeV2 = ICryptoFoxesStakingV2(_contract).getStakingTokenV2(_tokenId);

        _addRewards(foxesV2.owner, (BASE_RATE_V2 * (_currentTime - stackTimeV2 )) / 86400);
        _addRewards(_ownerOrigin, (BASE_RATE_V2 * (_currentTime - max(stackTimeOrigin, stackTimeV2) )) / 86400);
    }

    function calculationOriginDay(uint16 _tokenId) public view returns(uint256){

        address ownerOrigin = IERC721(cryptoFoxesOrigin).ownerOf(uint256(_tokenId));
        uint8 maxSlotsOrigin = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getOriginMaxSlot(uint16(_tokenId));
        Staking[] memory foxesV2 = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getV2ByOrigin(uint16(_tokenId));

        uint256 numberTokensOwner = 0;
        uint256 calculationV2 = 0;

        for(uint8 k = 0; k < foxesV2.length; k++){

            calculationV2 += BASE_RATE_V2;

            if(ownerOrigin == foxesV2[k].owner){
                numberTokensOwner += 1;
            }
        }
        if(numberTokensOwner == foxesV2.length && numberTokensOwner == maxSlotsOrigin){
            calculationV2 += calculationV2 * BONUS_MAX_OWNED / 10;
        }

        return BASE_RATE_ORIGIN + calculationV2;
    }
}