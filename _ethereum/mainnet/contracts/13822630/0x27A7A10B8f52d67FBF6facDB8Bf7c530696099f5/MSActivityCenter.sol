// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MSNFT.sol";
import "./ProxyAdmin.sol";

contract MSActivityCenter is ProxyAdmin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Charge {
        address token;
        uint256 price;
    }

    struct Activity {
        address nftContract;
        uint256 period;
        uint256 circulation;
        uint256 maxCirculation;
        bool fertile;
    }

    mapping(uint256 => Activity) internal activities;
    mapping(uint256 => Charge[]) internal activityCharges;

    event ActivityCreated(
        uint256 activityId,
        Charge[] charges,
        address nftContract,
        uint256 period,
        uint256 maxCirculation,
        bool fertile
    );
    event Sale(
        uint256 activityId,
        address nftContract,
        address buyer,
        uint256 tokenId,
        uint256 matronId,
        uint256 sireId,
        uint256 birthDate,
        uint256 breedCount,
        bool fertile
    );
    event Withdraw(address to, uint256 value);
    event WithdrawToken(address tokenAddress, address to, uint256 amount);

    modifier onlyPauser() {
        require(
            hasRole(roleName["PAUSER_ROLE"], _msgSender()),
            "MSActivityCenter: Must have pauser role"
        );
        _;
    }

    modifier onlyCreator() {
        require(
            hasRole(roleName["CREATOR_ROLE"], _msgSender()),
            "MSActivityCenter: Must have creator role"
        );
        _;
    }

    modifier onlyWithdrawer() {
        require(
            hasRole(roleName["WITHDRAWER_ROLE"], _msgSender()),
            "MSActivityCenter: Must have withdrawer role"
        );
        _;
    }

    modifier checkSale(uint256 activityId, uint256 tokenQuantity) {
        require(
            activities[activityId].period != 0,
            "MSActivityCenter: Period cannot be 0"
        );
        require(
            tokenQuantity <= 10,
            "MSActivityCenter: TokenQuantity exceeds 10"
        );
        require(
            activities[activityId].period >= block.timestamp,
            "MSActivityCenter: This activity is out of date"
        );
        require(
            activities[activityId].circulation + tokenQuantity <=
                activities[activityId].maxCirculation,
            "MSActivityCenter: The circulation exceeds max circulation"
        );
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function withdraw(address payable _to) public whenNotPaused onlyWithdrawer {
        require(
            address(this).balance != 0,
            "MSActivityCenter: No enough ETH to withdraw"
        );
        uint256 value = address(this).balance;
        (bool success, ) = _to.call{value: value}("");
        require(
            success,
            "MSActivityCenter: Unable to send value, recipient may have reverted"
        );
        emit Withdraw(_to, value);
    }

    function withdrawTokens(address[] calldata _tokens, address _to)
        public
        whenNotPaused
        onlyWithdrawer
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 balance = IERC20Upgradeable(_tokens[i]).balanceOf(
                address(this)
            );
            require(
                balance != 0,
                "MSActivityCenter: No enough ERC20 token to withdraw"
            );
            IERC20Upgradeable(_tokens[i]).safeTransfer(_to, balance);
            emit WithdrawToken(_tokens[i], _to, balance);
        }
    }

    function getActivity(uint256 _activityId)
        public
        view
        returns (Activity memory)
    {
        return activities[_activityId];
    }

    function getActivityCharges(uint256 _activityId)
        public
        view
        returns (Charge[] memory)
    {
        return activityCharges[_activityId];
    }

    function unsetActivity(uint256 _activityId)
        public
        whenNotPaused
        onlyCreator
    {
        activities[_activityId].period = 0;
        delete activityCharges[_activityId];
    }

    function setActivity(
        uint256 _activityId,
        Charge[] calldata _charges,
        address _nftContract,
        uint256 _period,
        uint256 _maxCirculation,
        bool _fertile
    ) public whenNotPaused onlyCreator {
        require(_period != 0, "MSActivityCenter: Period cannot be 0");
        require(
            _charges.length >= 1,
            "MSActivityCenter: Charges length is less than 1"
        );

        activities[_activityId] = Activity(
            _nftContract,
            _period,
            0,
            _maxCirculation,
            _fertile
        );

        delete activityCharges[_activityId];

        for (uint256 i = 0; i < _charges.length; i++) {
            activityCharges[_activityId].push(_charges[i]);
        }

        emit ActivityCreated(
            _activityId,
            _charges,
            _nftContract,
            _period,
            _maxCirculation,
            _fertile
        );
    }

    function sale(uint256 _activityId, uint256 _tokenQuantity)
        public
        payable
        whenNotPaused
        checkSale(_activityId, _tokenQuantity)
    {
        chargeTokens(_activityId, _tokenQuantity);
        _mint(_activityId, _msgSender(), _tokenQuantity, activities[_activityId].fertile);
    }

    function privateSale(
        uint256 _activityId,
        address _to,
        uint256 _tokenQuantity
    )
        public
        payable
        onlyCreator
        whenNotPaused
        checkSale(_activityId, _tokenQuantity)
    {
        _mint(_activityId, _to, _tokenQuantity, activities[_activityId].fertile);
    }

    function _mint(
        uint256 _activityId,
        address _to,
        uint256 _tokenQuantity,
        bool _fertile
    ) internal {
        MSNFT nft = MSNFT(activities[_activityId].nftContract);
        for (uint256 i = 0; i < _tokenQuantity; i++) {
            uint256 tokenId = nft.mint(_to, 0, 0, 0, _fertile);
            MSNFT.TokenMetadata memory metadata = nft.getTokenMetadata(tokenId);
            emit Sale(
                _activityId,
                activities[_activityId].nftContract,
                _to,
                tokenId,
                metadata.matronId,
                metadata.sireId,
                metadata.birthDate,
                metadata.breedCount,
                metadata.fertile
            );
        }
        activities[_activityId].circulation += _tokenQuantity;
    }

    function chargeTokens(uint256 _activityId, uint256 _tokenQuantity) internal {
        for (uint256 i = 0; i < activityCharges[_activityId].length; i++) {
            if (activityCharges[_activityId][i].token == address(0)) {
                require(
                    msg.value ==
                        activityCharges[_activityId][i].price * _tokenQuantity,
                    "MSActivityCenter: Send wrong ETH value"
                );
            } else {
                require(
                    IERC20Upgradeable(activityCharges[_activityId][i].token)
                        .allowance(_msgSender(), address(this)) >=
                        activityCharges[_activityId][i].price * _tokenQuantity,
                    "MSActivityCenter: Approved insufficient ERC20 tokens"
                );
                IERC20Upgradeable(activityCharges[_activityId][i].token)
                    .safeTransferFrom(
                        _msgSender(),
                        address(this),
                        activityCharges[_activityId][i].price * _tokenQuantity
                    );
            }
        }
    }
}
