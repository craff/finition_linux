--
-- Base de données : `scripts`
--

-- --------------------------------------------------------

--
-- Structure de la table `hostnames`
--

CREATE TABLE `hostnames` (
  `MAC` varchar(32) NOT NULL,    -- MAC ADDRESS
  `hostname` text DEFAULT NULL,  -- hostname
  `room` text DEFAULT NULL       -- lieu
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Structure de la table `script`
--
-- Cette table stocke tous les scripts à exécuter.

CREATE TABLE `script` (
  `id` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp(),
  `name` text NOT NULL,      -- nom du script
  `script` text NOT NULL,    -- le script bash
  `input` text DEFAULT NULL  -- optionnel: le stdin du script
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Structure de la table `run`
--
-- Cette table stocke tous les runs du script, le stdout et le stderr.
-- le script sera relancée tant que le exit_code n'est pas null. 

CREATE TABLE `run` (
  `uid` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp(),
  `MAC` text NOT NULL,
  `outputs` text NOT NULL,
  `errors` text NOT NULL,
  `exit_code` int(11) NOT NULL,
  `id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


--
-- Index pour les tables déchargées
--
