// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./Ownable.sol";
import "./IterableMapping.sol";

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
