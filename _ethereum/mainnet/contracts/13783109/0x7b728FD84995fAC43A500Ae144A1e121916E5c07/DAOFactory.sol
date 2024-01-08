// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Context.sol";
import "./IDAOFactory.sol";
import "./IDAOToken.sol";
import "./MintMath.sol";
import "./IDAOFactoryStore.sol";
import "./Ownable.sol";
import "./DAOToken.sol";

contract DAOFactory is Context, Ownable, IDAOFactory {
    uint256 public VERSION = 1;
    address public override daoFactoryStoreAddress;

    constructor(address _owner, address _daoFactoryStoreAddress) {
        transferOwnership(_owner);
        daoFactoryStoreAddress = _daoFactoryStoreAddress;
    }

    function tokens(string memory _daoID) external view override returns (address token, uint256 version) {
        (token, version) = IDAOFactoryStore(daoFactoryStoreAddress).tokens(_daoID);
    }

    function staking() external view override returns (address attr) {
        attr = IDAOFactoryStore(daoFactoryStoreAddress).staking();
    }

    function deploy(
        string memory _daoID,
        address[] memory _genesisTokenAddressList,
        uint256[] memory _genesisTokenAmountList,
        uint256 _lpRatio,
        uint256 _lpTotalAmount,
        address payable _ownerAddress,
        MintMath.MintArgs memory _mintArgs,
        string memory _erc20Name,
        string memory _erc20Symbol
    ) external override returns (address token) {
        IDAOFactoryStore store = IDAOFactoryStore(daoFactoryStoreAddress);
        (address oldTokenAddress, ) = store.tokens(_daoID);

        if (oldTokenAddress != address(0)) {
            IDAOToken oldToken = IDAOToken(oldTokenAddress);
            require(_msgSender() == oldToken.owner(), 'NOT OWNER DO REDEPLOY');
        }
        token = address(
            new DAOToken(
                _genesisTokenAddressList,
                _genesisTokenAmountList,
                _lpRatio,
                _lpTotalAmount,
                address(this),
                _ownerAddress,
                _mintArgs,
                _erc20Name,
                _erc20Symbol
            )
        );
        store.addToken(_daoID, token, VERSION);
        emit Deploy(
            _daoID,
            _genesisTokenAddressList,
            _genesisTokenAmountList,
            _lpRatio,
            _lpTotalAmount,
            _ownerAddress,
            _mintArgs,
            _erc20Name,
            _erc20Symbol,
            token
        );
    }

    function destruct() external override onlyOwner {
        selfdestruct(payable(owner()));
    }
}
