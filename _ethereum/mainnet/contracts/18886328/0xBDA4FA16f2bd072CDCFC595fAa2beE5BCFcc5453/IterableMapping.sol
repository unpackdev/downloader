/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

//SPDX-License-Identifier: UNLICENSED
// File: contracts/IterableMapping.sol


pragma solidity 0.8.19;


// File: contracts/Context.sol


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
// File: contracts/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// File: contracts/game.sol


pragma solidity 0.8.19;



contract Game is Ownable {
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private playersScores;
    address public manager;
    address payable public address1;
    uint256 public playPrice = 1000000000000000; // 0.001 Matic
    uint256 public address1Share;
    bool public gameStarted = false;
    uint256 public highScore = 0;

    struct Player {
        address player;
        uint256 score;
    }

    // Evento para notificar cuando un jugador paga y juega
    event PlayerPaid(address indexed player, uint256 amount);

    modifier onlyManager() {
        require(manager == msg.sender, "Only manager can call this function.");
        _;
    }

    receive() external payable {}

    constructor(address payable _address1, address _manager) {
        manager = _manager;
        address1 = _address1;
        gameStarted = true; // remove on mainnet
    }

    function setAddress1(address payable _address1) external onlyOwner {
        address1 = _address1;
    }

    function setPlayPrice(uint256 _playPrice) external onlyOwner {
        playPrice = _playPrice;
    }

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    function enableGame() external onlyOwner {
        require(!gameStarted, "El juego ya ha comenzado.");
        gameStarted = true;
    }

    function setPlayerScore(
        address payable _player,
        uint256 _score
    ) external onlyManager {
        require(gameStarted, "El juego aun no ha comenzado.");
        highScore = _score;
        playersScores.set(_player, _score);
    }

    // Función para que un usuario pague el fee y juegue
    function play() external payable {
        require(gameStarted, "El juego aun no ha comenzado.");
        require(msg.value == playPrice, "Invalid amount of ETH.");

        // Calcula los shares para las direcciones
        address1Share = (msg.value * 30) / 100;

        // Transfiere los pagos a las direcciones
        (bool sent, ) = address1.call{value: address1Share}("");
        require(sent, "Failed to send Ether");

        // Registra al jugador
        playersScores.set(msg.sender, 0);

        // Emite un evento para notificar que un jugador ha pagado y jugado
        emit PlayerPaid(msg.sender, msg.value);
    }

    // Función para finalizar el juego y retirar el saldo restante
    function endGame() external onlyOwner {
        require(gameStarted, "El juego aun no ha comenzado.");
        require(
            playersScores.size() >= 3,
            "Debe haber al menos 3 jugadores para distribuir premios."
        );

        // Obtiene las tres mejores direcciones de jugadores por puntuación
        address[] memory topThreePlayers = getTopThreePlayers();

        // Calcula la parte para los tres ganadores (70% restante)
        uint256 remainingShare = address(this).balance;

        // Calcula las partes para los tres ganadores
        uint256 firstPlaceShare = (remainingShare * 40) / 100;
        uint256 secondPlaceShare = (remainingShare * 30) / 100;
        uint256 thirdPlaceShare = (remainingShare * 30) / 100;

        gameStarted = false;
        for (uint256 i = 0; i < playersScores.size(); i++) {
            playersScores.remove(playersScores.getKeyAtIndex(i));
        }
        highScore = 0;

        // Transfiere las partes a los tres ganadores
        (bool firstSent, ) = topThreePlayers[0].call{value: firstPlaceShare}(
            ""
        );
        require(firstSent, "Fallo al enviar Ether al primer ganador.");

        (bool secondSent, ) = topThreePlayers[1].call{value: secondPlaceShare}(
            ""
        );
        require(secondSent, "Fallo al enviar Ether al segundo ganador.");

        (bool thirdSent, ) = topThreePlayers[2].call{value: thirdPlaceShare}(
            ""
        );
        require(thirdSent, "Fallo al enviar Ether al tercer ganador.");
    }

    function clearRanking() external onlyOwner {
        for (uint256 i = 0; i < playersScores.size(); i++) {
            playersScores.remove(playersScores.getKeyAtIndex(i));
        }
        highScore = 0;
    }

    // Función para que el propietario vea todas las direcciones de los jugadores
    function getRanking() external view returns (Player[] memory) {
        Player[] memory players = new Player[](playersScores.size());
        for (uint256 i = 0; i < playersScores.size(); i++) {
            players[i] = Player({
                player: playersScores.getKeyAtIndex(i),
                score: playersScores.get(playersScores.getKeyAtIndex(i))
            });
        }
        return players;
    }

    // function for get top 3 players by score
    function getTopThreePlayers() public view returns (address[] memory) {
        address[] memory topThreePlayers = new address[](3);
        for (uint256 i = 0; i < playersScores.size(); i++) {
            if (
                playersScores.get(playersScores.getKeyAtIndex(i)) >
                playersScores.get(topThreePlayers[0])
            ) {
                topThreePlayers[2] = topThreePlayers[1];
                topThreePlayers[1] = topThreePlayers[0];
                topThreePlayers[0] = playersScores.getKeyAtIndex(i);
            } else if (
                playersScores.get(playersScores.getKeyAtIndex(i)) >
                playersScores.get(topThreePlayers[1])
            ) {
                topThreePlayers[2] = topThreePlayers[1];
                topThreePlayers[1] = playersScores.getKeyAtIndex(i);
            } else if (
                playersScores.get(playersScores.getKeyAtIndex(i)) >
                playersScores.get(topThreePlayers[2])
            ) {
                topThreePlayers[2] = playersScores.getKeyAtIndex(i);
            }
        }
        return topThreePlayers;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}