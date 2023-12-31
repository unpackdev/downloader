// File: contracts/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Loteria.sol

pragma solidity ^0.8.19;

// Importando la biblioteca OpenZeppelin para gestión de propiedad

/**
 * @title Loteria
 * @author Fidentis
 * @notice Este contrato implementa una lotería simple en la blockchain de Ethereum.
 * Los jugadores pueden comprar entradas con Ether, y una vez que se alcanza un número
 * determinado de jugadores, se selecciona un ganador al azar y se le otorga el premio.
 * También se incluye una cola para los jugadores si el número máximo de jugadores ha sido alcanzado.
 * El propietario del contrato puede retirar las ganancias generadas por la plataforma.
 */
contract Loteria is Ownable {
    address[] public jugadoresActuales;
    address[] public jugadoresEnCola;

    uint256 public constant entrada = 0.003 ether;
    uint256 public constant maxJugadores = 10;
    uint256 public balanceDeLaPlataforma;

    event Ganador(address indexed ganador, uint256 monto);
    event NuevoJugador(address indexed jugador);

    constructor() Ownable() {}

    function participar() external payable {
        require(msg.value == entrada, "Debes enviar 0.003 ETH");

        if (jugadoresActuales.length == maxJugadores) {
            jugadoresEnCola.push(msg.sender);
        } else {
            jugadoresActuales.push(msg.sender);
        }

        emit NuevoJugador(msg.sender);

        if (jugadoresActuales.length == maxJugadores) {
            _finalizarRonda();
        }
    }

    function _finalizarRonda() private {
        address ganador = jugadoresActuales[random() % maxJugadores];
        uint256 montoGanador = (entrada * maxJugadores * 85) / 100;

        payable(ganador).transfer(montoGanador);
        balanceDeLaPlataforma += (entrada * maxJugadores) - montoGanador;

        emit Ganador(ganador, montoGanador);

        uint256 jugadoresMovidos = min(maxJugadores, jugadoresEnCola.length);

        for (uint256 i = 0; i < jugadoresMovidos; i++) {
            jugadoresActuales[i] = jugadoresEnCola[i];
        }

        while (jugadoresActuales.length > jugadoresMovidos) {
            jugadoresActuales.pop();
        }

        for (
            uint256 i = 0;
            i < jugadoresEnCola.length - jugadoresMovidos;
            i++
        ) {
            jugadoresEnCola[i] = jugadoresEnCola[i + jugadoresMovidos];
        }
        for (uint256 i = 0; i < jugadoresMovidos; i++) {
            jugadoresEnCola.pop();
        }
    }

    function random() private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp,
                        jugadoresActuales
                    )
                )
            );
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function retirarGananciasPlataforma() external onlyOwner {
        uint balance = balanceDeLaPlataforma;
        balanceDeLaPlataforma = 0;
        payable(owner()).transfer(balance); // usamos owner() que es una función proporcionada por Ownable
    }

    function obtenerJugadoresActuales()
        external
        view
        returns (address[] memory)
    {
        return jugadoresActuales;
    }

    function obtenerjugadoresEnCola() external view returns (address[] memory) {
        return jugadoresEnCola;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Esta funcion ha sido desactivada");
    }

    function transferOwnership(address) public view override onlyOwner {
        revert("Transferencia de propiedad desactivada");
    }
}