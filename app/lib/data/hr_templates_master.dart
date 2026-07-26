import 'package:simurh/models/hr_template.dart';

// =============================================================================
// Templates Master — Niveau stratégique (M1/M2)
// Scénarios multi-variables, incertitude, vision long terme
// Contexte ouest-africain, unités en FCFA
// =============================================================================

// ---------------------------------------------------------------------------
// 1. GPEC — Strategic Workforce Planning 5 ans
// ---------------------------------------------------------------------------
final HrTemplate gpec = HrTemplate(
  id: 'gpec',
  title: 'GPEC',
  description: 'Strategic workforce planning à 5 ans',
  level: 'master',
  icon: 'trending_up',
  role: "Vous êtes le DRH d\'une entreprise industrielle de 200 salariés.",
  context: "La direction vous confie la mise en place d\'une GPEC sur 5 ans. "
      "L\'entreprise est confrontée à un départ massif de seniors (30% des effectifs "
      "partiront en retraite d\'ici 3 ans) et à une digitalisation rapide de ses "
      "métiers coeur. Le COMEX attend un plan réaliste avec des indicateurs précis "
      "et un budget maîtrisé de 500 millions FCFA sur 5 ans pour la formation. "
      "Par ailleurs, le marché du travail local manque de profils techniques qualifiés, "
      "ce qui oblige à envisager des solutions de mobilité interne et de tutorat. "
      "Le plan devra également intégrer les objectifs de la politique RSE de l\'entreprise.",
  objectives: [
    'Analyser les écarts de compétences actuels et futurs',
    'Élaborer un plan d\'action pluriannuel de développement des compétences',
    'Anticiper les besoins en recrutement et formation',
    'Proposer une politique de mobilité interne et de tutorat',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Analyse stratégique', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Cohérence du plan', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Indicateurs pertinents', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Budgétisation réaliste', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_formation',
      label: 'Budget formation annuel',
      description: 'Montant alloué à la formation par an',
      type: DecisionType.currency,
      min: 20000000,
      max: 100000000,
      defaultValue: 50000000,
      step: 5000000,
    ),
    DecisionParam(
      id: 'effectifs_cibles',
      label: 'Effectifs cibles fin de période 5',
      description: 'Taille de l\'effectif visée à horizon 5 ans',
      type: DecisionType.integer,
      min: 180,
      max: 250,
      defaultValue: 220,
      step: 5,
    ),
    DecisionParam(
      id: 'recrutement_externe',
      label: 'Part de recrutement externe',
      description: '% des postes ouverts pourvus par recrutement externe',
      type: DecisionType.percentage,
      min: 10,
      max: 70,
      defaultValue: 40,
      step: 5,
    ),
    DecisionParam(
      id: 'mobilite_interne',
      label: 'Taux de mobilité interne cible',
      description: '% des postes pourvus via mobilité interne / reconversion',
      type: DecisionType.percentage,
      min: 10,
      max: 60,
      defaultValue: 30,
      step: 5,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_adequation',
      label: "Taux d\'adéquation compétences",
      unit: '%',
      description: 'Compétences disponibles vs requises',
    ),
    SuccessMetric(
      id: 'cout_formation_par_salarie',
      label: 'Coût formation par salarié',
      unit: 'FCFA',
      description: 'Budget formation / effectif annuel moyen',
    ),
    SuccessMetric(
      id: 'taux_mobilite',
      label: 'Taux de mobilité interne',
      unit: '%',
      description: '% des postes pourvus en interne',
    ),
    SuccessMetric(
      id: 'taux_depart_anticipe',
      label: 'Départs anticipés évités',
      unit: '%',
      description: '% des départs seniors anticipés et gérés',
    ),
  ],
  decisionPeriods: 5,
  rules: ['Chaque période = 1 an', 'Les départs en retraite sont connus dès la période 1'],
  constraints: [
    'Croissance des effectifs limitée à 10% par an',
    'Budget formation total plafonné à 500 millions FCFA sur 5 ans',
  ],
  resourceContent: ResourceContent(
    summary: "La Gestion Prévisionnelle des Emplois et des Compétences (GPEC) est une "
        "démarche stratégique qui consiste à anticiper les besoins en compétences "
        "pour aligner les ressources humaines avec la stratégie de l\'entreprise. "
        "Elle repose sur l\'analyse des écarts entre les compétences disponibles "
        "et les compétences requises à moyen terme (3-5 ans). La GPEC permet de "
        "réduire les tensions de recrutement, d\'optimiser la masse salariale et "
        "de sécuriser les parcours professionnels des salariés. Dans le contexte "
        "ouest-africain, elle est un outil clé pour faire face à la rareté des "
        "talents et aux mutations économiques rapides.",
    keyConcepts: [
      'GPEC',
      'Référentiel compétences',
      'Workforce planning',
      'Cartographie des métiers sensibles',
      'Plan de formation pluriannuel',
      'Mobilité interne et reconversion',
      'Gestion des âges et des seniors',
      'Entretien professionnel et GPEC',
      'Dispositif FAFP (Fonds de Développement de la Formation Professionnelle)',
      'Bilan social et indicateurs RH',
    ],
    sections: [
      ResourceSection(
        title: '1. Définition et cadre légal de la GPEC',
        content: "La GPEC est définie par la loi comme une obligation pour les "
            "entreprises d\'au moins 300 salariés, mais elle constitue une bonne "
            "pratique pour toutes les organisations. Elle repose sur un diagnostic "
            "partagé des emplois et des compétences, une identification des écarts, "
            "et la définition d\'un plan d\'action. En Côte d\'Ivoire, le cadre "
            "réglementaire s\'inspire du modèle français tout en intégrant les "
            "spécificités du marché local (secteur informel, pénurie de certains "
            "profils). L\'accord de GPEC peut être négocié avec les partenaires "
            "sociaux dans le cadre de la négociation collective obligatoire.",
      ),
      ResourceSection(
        title: '2. Méthodologie d\'analyse des écarts',
        content: "L\'analyse des écarts se déroule en quatre étapes. D\'abord, le "
            "recensement des compétences actuelles via les fiches de poste et les "
            "entretiens professionnels. Ensuite, la projection des besoins futurs "
            "à partir du plan stratégique de l\'entreprise. Puis, le calcul des "
            "écarts quantitatifs (nombre de postes) et qualitatifs (niveau de "
            "compétence). Enfin, la priorisation des actions de réduction des "
            "écarts selon leur criticité et leur urgence. Les outils mobilisés "
            "incluent la matrice de polyvalence, la cartographie des métiers "
            "sensibles, et les indicateurs de pyramide des âges.",
      ),
      ResourceSection(
        title: '3. Plan d\'action et budgétisation',
        content: "Le plan d\'action GPEC comprend quatre leviers principaux : "
            "le recrutement externe, la formation professionnelle, la mobilité "
            "interne, et l\'aménagement des fins de carrière. Chaque levier doit "
            "être budgétisé de manière réaliste. Au sein de l\'UEMOA, les "
            "entreprises peuvent solliciter des financements auprès du FAFP ou "
            "des OPCO locaux pour la formation. Le plan doit également intégrer "
            "un volet de gestion prévisionnelle des emplois sensibles (métiers "
            "en tension). Le suivi s\'effectue via un tableau de bord RH avec "
            "des indicateurs trimestriels.",
      ),
      ResourceSection(
        title: '4. Pilotage et évaluation',
        content: "Le pilotage de la GPEC repose sur des revues de direction "
            "semestrielles et des comités de pilotage associant les managers "
            "opérationnels. Les principaux indicateurs de suivi sont le taux "
            "d\'adéquation compétences/poste, le taux de mobilité, le taux de "
            "départ anticipé géré, et le retour sur investissement formation. "
            "La réussite de la GPEC dépend de l\'implication des managers de "
            "proximité et de la qualité du dialogue social. La démarche doit "
            "être révisée annuellement pour s\'adapter aux évolutions du contexte "
            "économique et réglementaire.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 2. Rémunération stratégique — Politique salariale et packages
// ---------------------------------------------------------------------------
final HrTemplate remuneration = HrTemplate(
  id: 'remuneration',
  title: 'Rémunération stratégique',
  description: 'Politique salariale, packages et performance',
  level: 'master',
  icon: 'payments',
  role: "Vous êtes le DRH d\'une entreprise de services numériques de 350 salariés à Bamako.",
  context: "Le CEO vous demande de repenser entièrement la politique de rémunération "
      "pour attirer et retenir les talents dans un secteur ultra-concurrentiel. "
      "La masse salariale représente 55% du chiffre d\'affaires et le turnover "
      "des développeurs atteint 28% par an. Vous devez concevoir un système de "
      "rémunération compétitif incluant un fixe, une part variable, des avantages "
      "extralégaux et un intéressement collectif. Le marché local du numérique "
      "est en plein essor mais les profils rares. Votre budget d\'augmentation "
      "est limité à 8% de la masse salariale et vous devez arbitrer entre "
      "augmentations générales, promotions individuelles et prime de performance.",
  objectives: [
    'Concevoir une politique de rémunération compétitive et équitable',
    'Définir les critères de performance pour la part variable',
    'Proposer un package d\'avantages extralégaux attractifs',
    'Équilibrer maîtrise des coûts et rétention des talents',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Diagnostic salarial', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Cohérence stratégique', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Équité interne/externe', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Faisabilité financière', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'augmentation_generale',
      label: 'Augmentation générale',
      description: '% d\'augmentation générale appliqué à tous les salariés',
      type: DecisionType.percentage,
      min: 0,
      max: 5,
      defaultValue: 2,
      step: 0.5,
    ),
    DecisionParam(
      id: 'enveloppe_promotions',
      label: 'Enveloppe promotions',
      description: 'Budget réservé aux augmentations individuelles et promotions',
      type: DecisionType.currency,
      min: 10000000,
      max: 150000000,
      defaultValue: 50000000,
      step: 5000000,
    ),
    DecisionParam(
      id: 'part_variable',
      label: 'Part variable cible',
      description: '% du salaire de base attribué sous forme de bonus',
      type: DecisionType.percentage,
      min: 5,
      max: 30,
      defaultValue: 15,
      step: 2,
    ),
    DecisionParam(
      id: 'budget_avantages',
      label: 'Budget avantages extralégaux',
      description: 'Budget annuel par salarié pour avantages (mutuelle, transport, tickets restaurant)',
      type: DecisionType.currency,
      min: 200000,
      max: 1500000,
      defaultValue: 500000,
      step: 100000,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'turnover_attendue',
      label: 'Turnover prévisionnel',
      unit: '%',
      description: 'Taux de rotation du personnel après réforme',
    ),
    SuccessMetric(
      id: 'masse_salariale',
      label: 'Masse salariale',
      unit: 'FCFA',
      description: 'Évolution de la masse salariale totale',
    ),
    SuccessMetric(
      id: 'competitivite',
      label: 'Indice de compétitivité',
      unit: '/100',
      description: 'Positionnement vs marché (benchmark)',
    ),
  ],
  decisionPeriods: 3,
  rules: [
    '3 périodes de simulation = 3 ans',
    'L\'enveloppe globale ne peut excéder +8% de la masse salariale par an',
  ],
  constraints: [
    'Le budget total augmentations (générale + promotions) ≤ 8% masse salariale',
    'L\'équité interne doit être respectée (ratio max 1:8 entre plus bas et plus haut salaire)',
  ],
  resourceContent: ResourceContent(
    summary: "La politique de rémunération est un levier stratégique majeur pour "
        "attirer, motiver et fidéliser les talents. Elle comprend la rémunération "
        "fixe (salaire de base), la rémunération variable (primes, bonus, "
        "intéressement), et les avantages extralégaux (mutuelle, transport, "
        "logement). Dans le contexte ouest-africain, la compétition pour les "
        "talents numériques impose une réflexion approfondie sur le mix "
        "rémunérationnel. Une politique bien conçue équilibre la compétitivité "
        "externe (benchmark), l\'équité interne (grille de classification), "
        "et la soutenabilité financière.",
    keyConcepts: [
      'Masse salariale',
      'Benchmark de rémunération',
      'Politique de rémunération',
      'Équité interne vs externe',
      'Part variable et intéressement',
      'Package global (Total Reward)',
      'Classification et grille salariale',
      'Comité de rémunération',
      'NAO — Négociation Annuelle Obligatoire',
      'CNPS et charges sociales',
    ],
    sections: [
      ResourceSection(
        title: '1. Diagnostic et benchmark',
        content: "La première étape consiste à réaliser un diagnostic complet "
            "de la politique salariale actuelle : analyse de la masse salariale, "
            "du coût moyen par collaborateur, et de la dispersion des salaires. "
            "Un benchmark externe est indispensable pour positionner l\'entreprise "
            "sur le marché de l\'emploi local. En Côte d\'Ivoire, des études "
            "salariales sont publiées par le cabinet Deloitte, le groupe "
            "Afriwise, et l\'APBEF. L\'analyse des fourchettes de salaires par "
            "métier et par niveau d\'expérience permet d\'identifier les "
            "déséquilibres et les risques de perte de talents.",
      ),
      ResourceSection(
        title: '2. Architecture du système de rémunération',
        content: "Le système de rémunération articule plusieurs composantes. "
            "Le salaire de base est déterminé par la classification des postes. "
            "La part variable est indexée sur la performance individuelle et/ou "
            "collective. L\'intéressement et la participation sont des dispositifs "
            "légaux ou conventionnels qui associent les salariés aux résultats "
            "de l\'entreprise. Les avantages extralégaux (mutuelle, logement de "
            "fonction, véhicule, téléphone, ticket-restaurant) peuvent "
            "représenter 15 à 30% du package total et sont un facteur clé de "
            "différenciation sur le marché ouest-africain.",
      ),
      ResourceSection(
        title: '3. Gestion des performances et rétention',
        content: "Le lien entre rémunération et performance doit être transparent "
            "et perçu comme équitable par les collaborateurs. Un système "
            "d\'évaluation annuelle avec des objectifs SMART permet de déterminer "
            "les augmentations individuelles et les bonus. Pour retenir les "
            "hauts potentiels, des mécanismes spécifiques existent : stock-options, "
            "bonus de signature, clauses de non-concurrence (avec contrepartie "
            "financière), et plans de rétention pluriannuels. Dans le secteur "
            "numérique, la rotation rapide des talents impose une révision "
            "annuelle des packages pour les postes critiques.",
      ),
      ResourceSection(
        title: '4. Cadre légal et dialogue social',
        content: "La politique salariale doit respecter le cadre réglementaire : "
            "SMIG (60 000 FCFA en Côte d\'Ivoire depuis 2022), conventions "
            "collectives, et obligations déclaratives auprès de la CNPS. Les "
            "NAO (Négociations Annuelles Obligatoires) sont un temps fort du "
            "dialogue social qui aboutit à un accord ou un procès-verbal de "
            "désaccord. Le comité de rémunération (dans les grands groupes) "
            "valide les propositions et veille à la conformité avec la politique "
            "RSE. La transparence sur les critères et les grilles est un facteur "
            "climat social déterminant.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 3. Stratégie RH — Alignment RH/Business et ROI RH
// ---------------------------------------------------------------------------
final HrTemplate strategieRh = HrTemplate(
  id: 'strategie_rh',
  title: 'Stratégie RH',
  description: 'Alignment RH/business, ROI des initiatives RH',
  level: 'master',
  icon: 'hub',
  role: "Vous êtes le DRH d\'un groupe bancaire de 800 salariés présent dans 5 pays de l\'UEMOA.",
  context: "Le nouveau CEO, issu de la finance, vous demande de démontrer la "
      "valeur ajoutée de la fonction RH en alignant la stratégie RH sur le plan "
      "stratégique du groupe : digitalisation bancaire, expansion régionale et "
      "amélioration de l\'expérience client. Il souhaite un plan RH 3 ans avec "
      "des indicateurs de performance clairs (ROI RH). Vous héritez d\'une "
      "direction RH perçue comme purement administrative. Le budget RH "
      "(hors masse salariale) est de 1,2 milliard FCFA. La concurrence sur "
      "les talents bancaires est féroce, notamment avec les fintechs. Vous "
      "devez prioriser les investissements RH et démontrer leur impact sur "
      "la performance business.",
  objectives: [
    'Définir une stratégie RH alignée sur les objectifs business du groupe',
    'Prioriser les investissements RH à fort retour sur investissement',
    'Concevoir un tableau de bord RH stratégique',
    'Proposer une transformation de la fonction RH vers un modèle de business partner',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Diagnostic stratégique', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Alignement business', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Indicateurs et ROI', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Innovation RH', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_recrutement',
      label: 'Budget recrutement et marque employeur',
      description: 'Budget annuel pour le recrutement et la marque employeur',
      type: DecisionType.currency,
      min: 50000000,
      max: 400000000,
      defaultValue: 150000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'budget_formation_strategique',
      label: 'Budget formation stratégique',
      description: 'Budget annuel alloué à la formation stratégique (digital, management, client)',
      type: DecisionType.currency,
      min: 100000000,
      max: 500000000,
      defaultValue: 250000000,
      step: 25000000,
    ),
    DecisionParam(
      id: 'budget_digitalisation_rh',
      label: 'Budget digitalisation RH',
      description: 'Investissement dans les outils RH (ATS, SIRH, HR analytics)',
      type: DecisionType.currency,
      min: 50000000,
      max: 300000000,
      defaultValue: 150000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'budget_qvt',
      label: 'Budget QVT et engagement',
      description: 'Budget annuel pour la qualité de vie au travail et l\'engagement',
      type: DecisionType.currency,
      min: 20000000,
      max: 150000000,
      defaultValue: 60000000,
      step: 10000000,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'roi_rh',
      label: 'ROI des initiatives RH',
      unit: '%',
      description: 'Retour sur investissement des projets RH',
    ),
    SuccessMetric(
      id: 'satisfaction_manager',
      label: 'Satisfaction managers (NPS)',
      unit: '/100',
      description: 'Score de satisfaction des managers sur le service RH',
    ),
    SuccessMetric(
      id: 'taux_engagement',
      label: 'Taux d\'engagement collaborateurs',
      unit: '%',
      description: 'Score d\'engagement mesuré par enquête annuelle',
    ),
  ],
  decisionPeriods: 3,
  rules: [
    '3 périodes = 3 ans',
    'Chaque période commence par un comité stratégique RH',
  ],
  constraints: [
    'Budget RH total (hors masse salariale) = 1,2 milliard FCFA/an',
    'Un projet RH doit montrer un ROI positif à 18 mois',
  ],
  resourceContent: ResourceContent(
    summary: "La stratégie RH consiste à aligner la gestion des ressources humaines "
        "avec la stratégie globale de l\'entreprise pour créer de la valeur durable. "
        "Elle s\'appuie sur le modèle de Dave Ulrich (Business Partner) pour "
        "transformer la fonction RH de support administratif en partenaire "
        "stratégique. La démonstration du ROI des initiatives RH est aujourd\'hui "
        "une exigence des directions générales. Les domaines clés incluent "
        "l\'acquisition de talents, le développement des compétences, la "
        "digitalisation RH, la marque employeur, et la QVT.",
    keyConcepts: [
      'Business Partner RH (modèle Ulrich)',
      'ROI RH et métriques',
      'Balanced Scorecard RH',
      'Stratégie de marque employeur',
      'Transformation digitale RH',
      'Employee Value Proposition (EVP)',
      'HR Scorecard (Becker, Huselid, Ulrich)',
      'Analyse des parties prenantes RH',
      'Benchmark RH sectoriel',
      'Gouvernance RH et comité stratégique',
    ],
    sections: [
      ResourceSection(
        title: '1. Le modèle de Business Partner RH',
        content: "Dave Ulrich a défini quatre rôles complémentaires pour la "
            "fonction RH : expert administratif (efficience), champion des "
            "salariés (engagement), agent de changement (transformation), et "
            "partenaire stratégique (alignement business). La maturité de la "
            "fonction RH se mesure à sa capacité à tenir ces quatre rôles "
            "simultanément. Dans le contexte ouest-africain, le modèle Ulrich "
            "doit être adapté à la taille des entreprises et à la maturité "
            "des pratiques RH. La formation des RRH et des business partners "
            "est un préalable indispensable à cette transformation.",
      ),
      ResourceSection(
        title: '2. Mesurer le ROI des initiatives RH',
        content: "Le calcul du ROI RH distingue l\'efficacité (résultats obtenus) "
            "et l\'efficience (coûts engagés). Les métriques classiques incluent "
            "le coût par recrutement, le time-to-hire, le taux de complétion "
            "des formations, et le turnover. Au niveau stratégique, on utilise "
            "des indicateurs composés comme le Human Capital Return on Investment "
            "(HCROI). La mise en place d\'un HR Scorecard permet de suivre "
            "l\'impact des initiatives RH sur la performance business.",
      ),
      ResourceSection(
        title: '3. Plan stratégique RH et priorités',
        content: "Le plan stratégique RH se décline en 4 axes : (1) Attirer "
            "et recruter les talents clés pour la transformation digitale, "
            "(2) Développer les compétences stratégiques via l\'Academy et le "
            "management, (3) Engager et fidéliser via une politique de "
            "rémunération et de QVT attractive, (4) Moderniser la fonction "
            "RH via le digital et les analytics. Chaque axe doit être "
            "budgétisé avec des milestones trimestriels et des KPIs "
            "spécifiques. Le comité de direction valide le plan et suit "
            "son exécution semestriellement.",
      ),
      ResourceSection(
        title: '4. Gouvernance et comité stratégique RH',
        content: "La gouvernance de la stratégie RH repose sur un comité "
            "stratégique RH trimestriel présidé par le CEO et composé du "
            "DRH, du DAF et des directeurs métiers. Ce comité examine les "
            "indicateurs clés, valide les investissements RH majeurs, et "
            "ajuste les priorités en fonction du contexte. Le reporting RH "
            "au COMEX doit être concis (1 page) avec les 5 indicateurs "
            "clés et les alertes éventuelles. La fonction RH doit apprendre "
            "à parler le langage du business : ROI, productivité, satisfaction "
            "client, part de marché.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 4. Gestion des talents — Rétention et hauts potentiels
// ---------------------------------------------------------------------------
final HrTemplate gestionTalents = HrTemplate(
  id: 'gestion_talents',
  title: 'Gestion des talents',
  description: 'Rétention, hauts potentiels et succession planning',
  level: 'master',
  icon: 'military_tech',
  role: "Vous êtes le DRH d\'une entreprise de télécommunications de 500 salariés.",
  context: "Le marché des télécoms en Afrique de l\'Ouest est en pleine mutation. "
      "Votre entreprise perd ses meilleurs éléments au profit des concurrents "
      "et des startups du numérique. Le CEO vous demande de mettre en place "
      "un dispositif de gestion des talents incluant l\'identification des "
      "hauts potentiels (HiPo), un plan de succession pour les 20 postes "
      "clés, et un programme de rétention dédié. Le budget alloué est de "
      "300 millions FCFA par an. La direction générale attend un plan concret "
      "avec des critères objectifs d\'identification des talents et des "
      "mesures de rétention innovantes adaptées au contexte local.",
  objectives: [
    'Identifier les critères d\'évaluation des hauts potentiels',
    'Concevoir un plan de succession pour les postes critiques',
    'Proposer un programme de rétention sur mesure',
    'Définir un parcours de développement accéléré pour les talents',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Modèle de détection', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Plan de succession', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Innovation rétention', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Budgétisation et faisabilité', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'taille_pool_talents',
      label: 'Taille du pool talents',
      description: 'Nombre de collaborateurs identifiés comme hauts potentiels',
      type: DecisionType.integer,
      min: 15,
      max: 60,
      defaultValue: 30,
      step: 5,
    ),
    DecisionParam(
      id: 'budget_parcours_talents',
      label: 'Budget annuel par talent',
      description: 'Budget de développement annuel par collaborateur du pool talents',
      type: DecisionType.currency,
      min: 3000000,
      max: 20000000,
      defaultValue: 8000000,
      step: 1000000,
    ),
    DecisionParam(
      id: 'duree_retention',
      label: 'Engagement rétention cible',
      description: 'Durée en mois pour laquelle le talent s\'engage à rester en échange des investissements',
      type: DecisionType.integer,
      min: 12,
      max: 48,
      defaultValue: 24,
      step: 6,
    ),
    DecisionParam(
      id: 'budget_primes_retention',
      label: 'Budget primes de rétention',
      description: 'Budget total annuel pour les primes de rétention exceptionnelles',
      type: DecisionType.currency,
      min: 20000000,
      max: 150000000,
      defaultValue: 60000000,
      step: 10000000,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_retention_talents',
      label: 'Taux de rétention des talents',
      unit: '%',
      description: '% des HiPo encore présents après 2 ans',
    ),
    SuccessMetric(
      id: 'ratio_succession',
      label: 'Ratio de succession couvert',
      unit: '%',
      description: '% des postes clés avec un successeur identifié et prêt',
    ),
    SuccessMetric(
      id: 'taux_mobilite_verticale',
      label: 'Taux de promotion interne',
      unit: '%',
      description: '% des postes cadres pourvus par promotion interne',
    ),
  ],
  decisionPeriods: 4,
  rules: [
    '4 périodes = 2 ans (semestres)',
    'Un talent non promu dans les 3 périodes quitte automatiquement le pool',
  ],
  constraints: [
    'Budget total gestion des talents = 300 millions FCFA/an',
    'Le pool talents ne peut excéder 12% de l\'effectif cadre',
  ],
  resourceContent: ResourceContent(
    summary: "La gestion des talents (Talent Management) est un processus "
        "stratégique qui vise à attirer, développer, et retenir les collaborateurs "
        "à haut potentiel. Elle comprend l\'identification des talents, le "
        "succession planning, le développement accéléré, et la rétention. "
        "Dans un marché concurrentiel comme l\'Afrique de l\'Ouest, les "
        "entreprises doivent déployer des stratégies de rétention spécifiques "
        "pour éviter la fuite de leurs meilleurs éléments vers les concurrents "
        "ou les startups du numérique.",
    keyConcepts: [
      'Haut potentiel (HiPo)',
      'Succession planning',
      '9-Box Matrix (Performance x Potentiel)',
      'Talent Review',
      'Parcours de développement accéléré',
      'Rétention et fidélisation',
      'Employee Value Proposition (EVP)',
      'Plan de carrière personnalisé',
      'Mentorat et coaching exécutif',
      'Golden handcuffs et clauses de rétention',
    ],
    sections: [
      ResourceSection(
        title: '1. Identification des hauts potentiels',
        content: "L\'identification des talents repose sur une double évaluation : "
            "la performance actuelle (résultats) et le potentiel futur (capacité "
            "à évoluer). La 9-Box Matrix est l\'outil le plus utilisé, croisant "
            "ces deux dimensions pour positionner chaque collaborateur. Les "
            "critères de potentiel incluent l\'agilité d\'apprentissage, la "
            "vision stratégique, l\'intelligence relationnelle, et la capacité "
            "à manager des équipes. Le processus de Talent Review est conduit "
            "annuellement par le comité de direction avec le HR Business "
            "Partner. L\'objectivité des critères est essentielle pour éviter "
            "les biais et assurer l\'équité de traitement.",
      ),
      ResourceSection(
        title: '2. Plan de succession',
        content: "Le plan de succession couvre les postes critiques (ceux dont "
            "le départ non anticipé mettrait en danger la performance). Pour "
            "chaque poste, on identifie un successeur immédiat (prêt dans les "
            "6 mois), un successeur à moyen terme (12-18 mois), et un "
            "successeur long terme (24-36 mois). Le plan de succession est "
            "revu annuellement en comité de direction. Dans le contexte "
            "ouest-africain, la diversification des successeurs (genre, "
            "origine) est un enjeu fort de la politique RSE. Les plans de "
            "succession doivent inclure un volet de développement des "
            "successeurs.",
      ),
      ResourceSection(
        title: '3. Développement accéléré des talents',
        content: "Les hauts potentiels bénéficient d\'un parcours de développement "
            "différencié : formations certifiantes, coaching individuel, "
            "participation à des projets transverses, mobilité internationale "
            "au sein du groupe, et mentoring par un membre du COMEX. Le "
            "programme de développement doit être co-construit avec le talent "
            "lui-même pour garantir son engagement. Les indicateurs de succès "
            "incluent le taux de complétion du parcours, la progression du "
            "participant dans la 9-Box, et le taux de mobilité ascendante. "
            "Chaque talent doit avoir un sponsor au COMEX qui suit son développement.",
      ),
      ResourceSection(
        title: '4. Stratégies de rétention',
        content: "La rétention des talents combine des leviers financiers et non "
            "financiers. Les leviers financiers incluent les primes de rétention "
            "pluriannuelles, l\'intéressement, et les augmentations différenciées. "
            "Les leviers non financiers sont souvent plus efficaces : sens au "
            "travail, autonomie, reconnaissance, équilibre vie pro/perso, et "
            "perspectives de carrière. Dans le contexte africain, la dimension "
            "communautaire et la fierté d\'appartenance sont des leviers puissants. "
            "Un entretien de rétention semestriel avec chaque talent permet "
            "d\'anticiper les risques de départ.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 5. Conduite du changement RH — Transformation digitale
// ---------------------------------------------------------------------------
final HrTemplate conduiteChangement = HrTemplate(
  id: 'conduite_changement',
  title: 'Conduite du changement RH',
  description: 'Transformation digitale et accompagnement du changement',
  level: 'master',
  icon: 'sync_alt',
  role: "Vous êtes le DRH d\'une administration publique de 1200 agents en phase de digitalisation.",
  context: "Le gouvernement a lancé un vaste programme de digitalisation des "
      "ressources humaines de la fonction publique. Votre ministère pilote "
      "la réforme. Vous devez accompagner le changement auprès de 1200 "
      "agents, dont 60% ont plus de 20 ans d\'ancienneté et une culture "
      "administrative fortement ancrée. Le projet inclut le déploiement "
      "d\'un SIRH intégré, la dématérialisation des processus RH et "
      "l\'introduction du télétravail. Le budget de conduite du changement "
      "est de 250 millions FCFA sur 2 ans. Les syndicats sont méfiants "
      "et craignent une surveillance accrue et des suppressions de postes.",
  objectives: [
    'Élaborer un plan de conduite du changement sur 2 ans',
    'Identifier et mobiliser les relais du changement',
    'Gérer les résistances et communiquer efficacement',
    'Assurer l\'adoption durable des nouveaux outils et processus',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Diagnostic des impacts', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Plan d\'accompagnement', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Gestion des parties prenantes', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Indicateurs d\'adoption', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_communication',
      label: 'Budget communication interne',
      description: 'Budget pour les actions de communication et sensibilisation',
      type: DecisionType.currency,
      min: 10000000,
      max: 80000000,
      defaultValue: 30000000,
      step: 5000000,
    ),
    DecisionParam(
      id: 'nb_relais',
      label: 'Nombre de relais du changement',
      description: 'Nombre d\'agents ambassadeurs identifiés pour relayer la transformation',
      type: DecisionType.integer,
      min: 10,
      max: 80,
      defaultValue: 30,
      step: 5,
    ),
    DecisionParam(
      id: 'duree_accompagnement',
      label: 'Durée de l\'accompagnement',
      description: 'Durée en mois de la phase d\'accompagnement post-déploiement',
      type: DecisionType.integer,
      min: 3,
      max: 18,
      defaultValue: 9,
      step: 3,
    ),
    DecisionParam(
      id: 'budget_formation_accompagnement',
      label: 'Budget formation accompagnement',
      description: 'Budget pour la formation des agents aux nouveaux outils',
      type: DecisionType.currency,
      min: 30000000,
      max: 120000000,
      defaultValue: 60000000,
      step: 10000000,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_adoption',
      label: 'Taux d\'adoption des outils',
      unit: '%',
      description: '% d\'agents utilisant activement le nouveau SIRH',
    ),
    SuccessMetric(
      id: 'taux_resistance',
      label: 'Indice de résistance',
      unit: '/100',
      description: 'Niveau de résistance perçu (enquête climat social)',
    ),
    SuccessMetric(
      id: 'delai_appropriation',
      label: 'Délai d\'appropriation',
      unit: 'mois',
      description: 'Temps moyen pour une maîtrise satisfaisante des outils',
    ),
  ],
  decisionPeriods: 4,
  rules: [
    '4 périodes = 2 ans (semestrielles)',
    'Période 1 : préparation et diagnostic, Période 2 : déploiement pilote, Périodes 3-4 : généralisation',
  ],
  constraints: [
    'Budget total conduite du changement = 250 millions FCFA (non révisable)',
    'Au moins 60% des agents doivent être formés avant la fin de la période 3',
  ],
  resourceContent: ResourceContent(
    summary: "La conduite du changement est une démarche structurée pour "
        "accompagner les individus et les organisations dans la transition "
        "d\'un état actuel vers un état futur souhaité. Dans le contexte RH, "
        "elle s\'applique particulièrement aux transformations digitales "
        "(déploiement SIRH, digitalisation des processus) et aux réformes "
        "organisationnelles. Le modèle ADKAR (Awareness, Desire, Knowledge, "
        "Ability, Reinforcement) de Prosci est une référence pour structurer "
        "l\'accompagnement individuel du changement.",
    keyConcepts: [
      'ADKAR (Prosci)',
      'Courbe du changement (Kübler-Ross)',
      'Résistance au changement',
      'Relais et ambassadeurs du changement',
      'Conduite du changement',
      'Accompagnement post-déploiement',
      'Communication de crise',
      'Cartographie des parties prenantes',
      'Impact du changement',
      'Culture organisationnelle',
    ],
    sections: [
      ResourceSection(
        title: '1. Modèles et méthodologies de conduite du changement',
        content: "Plusieurs modèles théoriques structurent la conduite du "
            "changement. Le modèle ADKAR (Prosci) se concentre sur le "
            "parcours individuel : Awareness (prise de conscience du besoin), "
            "Desire (envie de participer), Knowledge (savoir comment changer), "
            "Ability (capacité à mettre en œuvre), Reinforcement (ancrage). "
            "Le modèle de Kotter propose 8 étapes séquentielles allant de "
            "l\'urgence à l\'ancrage. La courbe du changement de Kübler-Ross "
            "décrit les phases émotionnelles traversées par les individus : "
            "choc, déni, résistance, exploration, acceptation, engagement. "
            "Le choix du modèle dépend de la culture organisationnelle et "
            "de l\'ampleur du changement.",
      ),
      ResourceSection(
        title: '2. Diagnostic et cartographie des parties prenantes',
        content: "Avant tout changement, un diagnostic approfondi est nécessaire : "
            "analyse de l\'existant, identification des impacts (qui est touché "
            "et comment), et cartographie des parties prenantes (influence et "
            "attitude face au changement). La matrice intérêt/pouvoir permet "
            "de classer les parties prenantes en quatre catégories : à "
            "informer, à consulter, à impliquer, à convaincre. Les sponsors "
            "du changement (dirigeants) doivent être visiblement engagés. "
            "Les résistants doivent être écoutés et leurs préoccupations "
            "traitées : la résistance est souvent l\'expression de craintes légitimes.",
      ),
      ResourceSection(
        title: '3. Plan d\'accompagnement et communication',
        content: "Le plan d\'accompagnement articule quatre leviers : la "
            "communication (messages clairs, canaux adaptés, fréquence élevée), "
            "la formation (montée en compétence progressive), le support "
            "(hotline, super-utilisateurs, FAQ), et la reconnaissance "
            "(valorisation des ambassadeurs et des succès). La communication "
            "doit répondre au « Why » avant le « What » et le « How » : "
            "expliquer le sens du changement avant ses modalités concrètes. "
            "Les relais du changement (managers de proximité, pairs influents) "
            "sont formés et accompagnés pour diffuser le changement dans leurs équipes.",
      ),
      ResourceSection(
        title: '4. Mesure de l\'adoption et ancrage',
        content: "L\'adoption du changement se mesure via des indicateurs "
            "comportementaux (utilisation des nouveaux outils, respect "
            "des nouveaux processus) et attitudinaux (enquêtes de climat, "
            "taux de satisfaction). Le seuil critique d\'adoption est "
            "souvent fixé à 70% d\'utilisateurs actifs. L\'ancrage du "
            "changement nécessite des actions de renforcement : mise à "
            "jour des procédures, intégration dans les parcours d\'intégration "
            "des nouveaux entrants, et célébration des succès. Le risque "
            "de « rebond » (retour aux anciennes pratiques) est maximal "
            "dans les 6 mois suivant le déploiement.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 6. Relations sociales — NAO, syndicats, négociation
// ---------------------------------------------------------------------------
final HrTemplate relationsSociales = HrTemplate(
  id: 'relations_sociales',
  title: 'Relations sociales',
  description: 'NAO, syndicats, négociation collective',
  level: 'master',
  icon: 'groups',
  role: "Vous êtes le DRH d\'une entreprise agro-industrielle de 600 salariés.",
  context: "L\'entreprise traverse une restructuration partielle liée à la "
      "mécanisation de la production. Les syndicats, puissants dans le "
      "secteur, s\'opposent au plan social et menacent de déclencher une "
      "grève. Vous devez conduire les négociations annuelles obligatoires "
      "(NAO) dans un contexte tendu : l\'inflation est à 6%, le SMIG a "
      "augmenté de 10%, et la direction veut limiter l\'augmentation de la "
      "masse salariale à 4%. Trois organisations syndicales sont présentes "
      "dans l\'entreprise : deux majoritaires et une minoritaire. Le "
      "climat social est dégradé depuis la dernière grève de 8 jours.",
  objectives: [
    'Préparer et conduire les NAO dans un contexte de tension',
    'Proposer un accord collectif équilibré entre intérêts des salariés et contraintes financières',
    'Définir un plan de gestion des conflits sociaux',
    'Mettre en place un dialogue social constructif et pérenne',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Préparation des NAO', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Stratégie de négociation', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Qualité du dialogue social', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Gestion de crise', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'augmentation_nao',
      label: 'Augmentation générale NAO',
      description: '% d\'augmentation générale proposée en NAO',
      type: DecisionType.percentage,
      min: 0,
      max: 8,
      defaultValue: 4,
      step: 0.5,
    ),
    DecisionParam(
      id: 'prime_exceptionnelle',
      label: 'Prime exceptionnelle de pouvoir d\'achat',
      description: 'Montant de la prime exceptionnelle versée à tous les salariés',
      type: DecisionType.currency,
      min: 0,
      max: 500000,
      defaultValue: 150000,
      step: 25000,
    ),
    DecisionParam(
      id: 'mesures_accompagnement',
      label: 'Budget mesures accompagnement social',
      description: 'Budget pour des mesures sociales complémentaires (mutuelle, tickets restaurant, transport)',
      type: DecisionType.currency,
      min: 0,
      max: 100000000,
      defaultValue: 30000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'delai_mise_oeuvre',
      label: 'Délai de mise en œuvre',
      description: 'Nombre de mois avant application effective des mesures',
      type: DecisionType.integer,
      min: 1,
      max: 6,
      defaultValue: 3,
      step: 1,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_signature',
      label: 'Taux de signature syndicale',
      unit: '%',
      description: '% des organisations syndicales représentatives ayant signé l\'accord',
    ),
    SuccessMetric(
      id: 'cout_accord',
      label: 'Coût total de l\'accord',
      unit: 'FCFA',
      description: 'Impact financier total de l\'accord social',
    ),
    SuccessMetric(
      id: 'paix_sociale',
      label: 'Indice de paix sociale',
      unit: '/100',
      description: 'Score de climat social post-négociation',
    ),
  ],
  decisionPeriods: 3,
  rules: [
    '3 périodes = les 3 séances de NAO réglementaires',
    'Chaque période peut aboutir à un accord partiel ou total',
  ],
  constraints: [
    'La direction impose un plafond de 5% d\'augmentation de la masse salariale totale',
    'Un accord doit être signé par au moins une organisation majoritaire pour être valide',
  ],
  resourceContent: ResourceContent(
    summary: "Les relations sociales recouvrent l\'ensemble des interactions "
        "entre l\'employeur, les salariés et leurs représentants (syndicats, "
        "CSE). Les Négociations Annuelles Obligatoires (NAO) sont un temps "
        "fort du dialogue social : elles portent sur les salaires, le temps "
        "de travail, et le partage de la valeur ajoutée. Dans le contexte "
        "ouest-africain, le dialogue social est encadré par le code du "
        "travail et les conventions collectives sectorielles. Un climat "
        "social apaisé est un facteur clé de performance et d\'attractivité.",
    keyConcepts: [
      'NAO — Négociation Annuelle Obligatoire',
      'Représentativité syndicale',
      'Accord collectif',
      'Convention collective sectorielle',
      'Droit de grève et préavis',
      'CSE — Comité Social et Économique',
      'Section syndicale et délégué syndical',
      'Procès-verbal de désaccord',
      'Courbe des conflits sociaux',
      'Médiation et conciliation',
    ],
    sections: [
      ResourceSection(
        title: '1. Cadre juridique et acteurs du dialogue social',
        content: "Le dialogue social est encadré par le Code du Travail qui "
            "définit les règles de représentativité syndicale, le droit "
            "syndical, et les procédures de négociation. Les organisations "
            "syndicales représentatives (UGTCI, Dignité, FESACI, etc.) "
            "disposent d\'un monopole de négociation des accords collectifs. "
            "Le CSE (Comité Social et Économique) est l\'instance de dialogue "
            "permanente dans les entreprises d\'au moins 11 salariés. La "
            "loi impose la tenue des NAO chaque année dans les entreprises "
            "dotées de délégués syndicaux. La transparence des informations "
            "fournies aux négociateurs est une obligation légale.",
      ),
      ResourceSection(
        title: '2. Conduite des NAO : préparation et stratégie',
        content: "La préparation des NAO est cruciale : analyse de la masse "
            "salariale, benchmark sectoriel, étude des revendications "
            "syndicales, et définition de la marge de manœuvre financière. "
            "La stratégie de négociation distingue les sujets négociables "
            "des sujets non-négociables. Il est recommandé de commencer "
            "par les sujets les moins conflictuels pour créer une dynamique "
            "positive. Les réunions préparatoires avec la direction générale "
            "sont essentielles pour sécuriser les marges de manœuvre. "
            "Chaque séance de NAO donne lieu à un procès-verbal cosigné.",
      ),
      ResourceSection(
        title: '3. Thèmes et clauses des accords collectifs',
        content: "Les NAO portent obligatoirement sur les salaires (augmentations "
            "générales, primes), la durée du travail, et le partage de la "
            "valeur ajoutée (intéressement, participation). Depuis la loi "
            "ivoirienne de 2023, elles incluent aussi la QVT, l\'égalité "
            "professionnelle, et la mobilité durable. Les accords collectifs "
            "peuvent déroger aux dispositions légales dans un sens plus "
            "favorable aux salariés. La signature d\'un accord par des "
            "organisations représentant au moins 30% des voix (et sans "
            "opposition des organisations majoritaires) le rend applicable.",
      ),
      ResourceSection(
        title: '4. Gestion des conflits et prévention',
        content: "La prévention des conflits sociaux passe par un dialogue "
            "social régulier en dehors des NAO : réunions mensuelles CSE, "
            "information-consultation en amont des décisions impactant les "
            "salariés, et enquêtes de climat social. En cas de conflit, "
            "la procédure légale impose un préavis de grève de 72h et "
            "une tentative de conciliation. La médiation par l\'inspecteur "
            "du travail peut être sollicitée. L\'arbitrage (recours à un "
            "tiers) est possible en dernier ressort. Une communication de "
            "crise transparente est essentielle pour éviter l\'escalade.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 7. SIRH / RH digitale — Implémentation ATS/SIRH
// ---------------------------------------------------------------------------
final HrTemplate sirh = HrTemplate(
  id: 'sirh',
  title: 'SIRH et RH digitale',
  description: 'Implémentation ATS/SIRH, digitalisation RH',
  level: 'master',
  icon: 'computer',
  role: "Vous êtes le DRH d\'un groupe de distribution de 450 salariés avec 12 agences en Afrique de l\'Ouest.",
  context: "La gestion RH est encore largement manuelle : les dossiers "
      "papier, les congés gérés sur Excel, et la paie externalisée sans "
      "lien avec les données de présence. Le CEO vous a missionné pour "
      "sélectionner et déployer un SIRH intégré (paie, temps, "
      "administration, recrutement, formation). Le budget IT RH alloué "
      "est de 200 millions FCFA pour le projet. Vous devez choisir "
      "entre une solution cloud (plus rapide, moins chère) et une "
      "solution on-premise (plus sécurisée, souveraineté des données). "
      "Le projet doit être déployé en 18 mois et couvrir les 12 agences.",
  objectives: [
    'Sélectionner une solution SIRH adaptée au contexte régional',
    'Planifier le déploiement dans les 12 agences',
    'Gérer le changement et la formation des utilisateurs',
    'Assurer la qualité et la sécurité des données RH',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Analyse des besoins', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Choix solution et architecture', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Plan de déploiement', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Conformité et sécurité', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_sirh',
      label: 'Budget total SIRH',
      description: 'Budget total alloué au projet SIRH (licences, déploiement, formation)',
      type: DecisionType.currency,
      min: 80000000,
      max: 200000000,
      defaultValue: 150000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'solution_type',
      label: 'Type de solution',
      description: '0 = Cloud (SaaS), 100 = On-premise (serveurs locaux)',
      type: DecisionType.percentage,
      min: 0,
      max: 100,
      defaultValue: 50,
      step: 50,
    ),
    DecisionParam(
      id: 'modules_prioritaires',
      label: 'Modules prioritaires',
      description: 'Nombre de modules SIRH déployés en phase 1 (sur 8 modules disponibles)',
      type: DecisionType.integer,
      min: 2,
      max: 8,
      defaultValue: 4,
      step: 1,
    ),
    DecisionParam(
      id: 'duree_deploiement',
      label: 'Durée du déploiement',
      description: 'Durée totale en mois pour le déploiement complet',
      type: DecisionType.integer,
      min: 9,
      max: 24,
      defaultValue: 18,
      step: 3,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_couverture',
      label: 'Taux de couverture SIRH',
      unit: '%',
      description: '% des processus RH couverts par le SIRH',
    ),
    SuccessMetric(
      id: 'delai_roi',
      label: 'Délai de retour sur investissement',
      unit: 'mois',
      description: 'Temps nécessaire pour que le SIRH soit rentabilisé',
    ),
    SuccessMetric(
      id: 'taux_adoption_sirh',
      label: 'Taux d\'adoption par les managers',
      unit: '%',
      description: '% des managers utilisant activement les modules SIRH',
    ),
  ],
  decisionPeriods: 4,
  rules: [
    '4 périodes = 18 mois (trimestres)',
    'Période 1 : sélection et conception, Périodes 2-3 : déploiement par vagues, Période 4 : stabilisation',
  ],
  constraints: [
    'Budget IT RH total = 200 millions FCFA (inclut licences, infrastructure, formation)',
    'La solution doit être conforme au règlement UEMOA sur la protection des données',
  ],
  resourceContent: ResourceContent(
    summary: "Le Système d\'Information des Ressources Humaines (SIRH) est "
        "l\'ensemble des outils et processus qui automatisent et intègrent "
        "la gestion des données RH : administration du personnel, paie, "
        "gestion des temps, recrutement, formation, et évaluation. La "
        "digitalisation RH transforme la fonction RH en profondeur en "
        "libérant du temps administratif au profit d\'activités à valeur "
        "ajoutée. Dans le contexte africain, le SIRH doit tenir compte "
        "des contraintes de connectivité, de la réglementation locale, "
        "et de la diversité des pratiques selon les pays.",
    keyConcepts: [
      'SIRH intégré',
      'SaaS vs On-premise',
      'ATS — Applicant Tracking System',
      'Payroll et paie dématérialisée',
      'Data quality RH',
      'Workflow et BPM RH',
      'Portail collaborateur et self-service',
      'RGPD et protection des données (UEMOA)',
      'API et interopérabilité des systèmes',
      'Tableau de bord RH et BI',
    ],
    sections: [
      ResourceSection(
        title: '1. Architecture et typologie des SIRH',
        content: "Un SIRH moderne se compose de plusieurs modules intégrés : "
            "gestion administrative (état civil, contrats), paie et "
            "déclarations sociales, gestion des temps et absences, "
            "recrutement (ATS), formation (LMS), évaluation et talents, "
            "et portail collaborateur. L\'architecture peut être on-premise "
            "(serveurs hébergés localement) ou cloud (SaaS). Dans le "
            "contexte ouest-africain, les solutions cloud offrent une "
            "meilleure accessibilité multi-sites mais doivent composer "
            "avec des contraintes de bande passante. Les solutions "
            "on-premise garantissent la souveraineté des données mais "
            "nécessitent des compétences IT internes.",
      ),
      ResourceSection(
        title: '2. Déploiement et conduite du changement digital',
        content: "Le déploiement d\'un SIRH est un projet structurant qui suit "
            "les étapes classiques : cadrage (besoins, processus), "
            "sélection (RFP, démo, référence clients), conception "
            "(paramétrage, recettes), déploiement (pilote, généralisation), "
            "et stabilisation (support, optimisation). La conduite du "
            "changement est le facteur clé de succès : implication des "
            "futurs utilisateurs dès la conception, formation aux nouveaux "
            "outils, et accompagnement post-déploiement. Le déploiement "
            "par vagues (site pilote puis généralisation) permet de "
            "limiter les risques.",
      ),
      ResourceSection(
        title: '3. Qualité des données et conformité',
        content: "La qualité des données RH est un enjeu majeur du SIRH : des "
            "données inexactes ou obsolètes compromettent la fiabilité de "
            "la paie et des reportings. Un plan de nettoyage des données "
            "est nécessaire avant la mise en production. La conformité "
            "réglementaire est impérative : protection des données "
            "personnelles (loi 2013-450 en Côte d\'Ivoire), conservation "
            "des archives, et fiabilité des déclarations sociales (CNPS, "
            "impôts). Le Délégué à la Protection des Données (DPO) doit "
            "être associé au projet dès la phase de conception.",
      ),
      ResourceSection(
        title: '4. ROI et indicateurs de performance SIRH',
        content: "Le retour sur investissement d\'un SIRH se mesure sur "
            "plusieurs dimensions : réduction du temps administratif "
            "(évalué à 30-50% sur la paie et l\'administration), "
            "fiabilité accrue (réduction des erreurs de paie), "
            "amélioration de l\'expérience collaborateur (self-service, "
            "portail), et pilotage stratégique (tableaux de bord, "
            "analytics). Le délai de ROI typique est de 18 à 24 mois. "
            "Les indicateurs de performance incluent le taux d\'adoption, "
            "le temps de traitement des processus, et la satisfaction "
            "des utilisateurs.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 8. Audit RH — Diagnostic organisationnel
// ---------------------------------------------------------------------------
final HrTemplate auditRh = HrTemplate(
  id: 'audit_rh',
  title: 'Audit RH',
  description: 'Diagnostic organisationnel et performance RH',
  level: 'master',
  icon: 'search',
  role: "Vous êtes un consultant RH externe mandaté pour auditer la fonction RH d\'une entreprise minière de 1000 salariés.",
  context: "L\'entreprise minière fait face à une dégradation de son climat "
      "social et à un turnover élevé (35% sur les 12 derniers mois). "
      "La direction vous mandate pour réaliser un audit RH complet : "
      "processus, conformité, performance, et climat social. Vous "
      "disposez de 60 jours et d\'un budget de 50 millions FCFA pour "
      "conduire l\'audit. L\'entreprise exploite 3 sites miniers en "
      "zones rurales reculées et un siège à Abidjan. Les syndicats "
      "sont puissants et méfiants vis-à-vis de l\'audit. Vous devez "
      "produire un rapport avec des recommandations actionnables.",
  objectives: [
    'Évaluer la conformité légale et réglementaire des pratiques RH',
    'Analyser la performance des processus RH (recrutement, formation, paie)',
    'Diagnostiquer les causes du turnover et du climat social dégradé',
    'Formuler des recommandations prioritaires et un plan d\'action',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Périmètre et méthodologie', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Qualité du diagnostic', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Recommandations', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Plan d\'action', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_audit',
      label: 'Budget audit RH',
      description: 'Budget total pour la mission d\'audit',
      type: DecisionType.currency,
      min: 20000000,
      max: 80000000,
      defaultValue: 50000000,
      step: 5000000,
    ),
    DecisionParam(
      id: 'echantillon_sites',
      label: 'Nombre de sites audités',
      description: 'Nombre de sites visités dans le cadre de l\'audit (sur 4)',
      type: DecisionType.integer,
      min: 1,
      max: 4,
      defaultValue: 3,
      step: 1,
    ),
    DecisionParam(
      id: 'profondeur_analyse',
      label: 'Profondeur de l\'analyse',
      description: '25 = Revue documentaire, 50 = Audit terrain, 75 = Audit avec entretiens, 100 = Audit complet + benchmarking',
      type: DecisionType.percentage,
      min: 25,
      max: 100,
      defaultValue: 75,
      step: 25,
    ),
    DecisionParam(
      id: 'duree_mission',
      label: 'Durée de la mission',
      description: 'Nombre de jours pour la mission d\'audit',
      type: DecisionType.integer,
      min: 30,
      max: 90,
      defaultValue: 60,
      step: 5,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'score_conformite',
      label: 'Score de conformité',
      unit: '%',
      description: '% des exigences légales et réglementaires respectées',
    ),
    SuccessMetric(
      id: 'score_maturite',
      label: 'Score de maturité RH',
      unit: '/100',
      description: 'Indice de maturité des processus RH',
    ),
    SuccessMetric(
      id: 'taux_recommandations',
      label: 'Taux de recommandations retenues',
      unit: '%',
      description: '% des recommandations acceptées par la direction',
    ),
  ],
  decisionPeriods: 1,
  rules: [
    '1 période unique de 60 jours',
    'Le rapport final doit inclure un plan d\'action priorisé avec échéances',
  ],
  constraints: [
    'Budget maximum = 80 millions FCFA',
    'L\'audit doit couvrir au moins 2 sites pour être représentatif',
    'Les entretiens individuels sont limités à 10% de l\'effectif',
  ],
  resourceContent: ResourceContent(
    summary: "L\'audit RH est une démarche systématique et objective d\'évaluation "
        "des pratiques, processus et performances de la fonction RH. Il vise "
        "à identifier les écarts entre les pratiques observées et les "
        "référentiels (légaux, normatifs, bonnes pratiques) et à formuler "
        "des recommandations d\'amélioration. L\'audit peut être légal "
        "(inspection du travail), normatif (ISO 30400), ou stratégique "
        "(alignement business). Il couvre typiquement l\'administration, "
        "la paie, le recrutement, la formation, les relations sociales, "
        "et la performance RH.",
    keyConcepts: [
      'Audit RH',
      'Référentiel d\'audit (ISO 30400, normes OHADA)',
      'Conformité sociale',
      'Revue de processus',
      'Entretien d\'audit et techniques d\'investigation',
      'Échantillonnage et preuves d\'audit',
      'Rapport d\'audit et plan d\'action',
      'Risk assessment RH',
      'Benchmarking RH sectoriel',
      'Matrice de maturité RH',
    ],
    sections: [
      ResourceSection(
        title: '1. Cadre et méthodologie de l\'audit RH',
        content: "Un audit RH suit une méthodologie structurée : (1) Cadrage "
            "et planification (définition du périmètre, des critères, et "
            "du plan d\'audit), (2) Collecte des données (documents, "
            "entretiens, observations, questionnaires), (3) Analyse et "
            "évaluation (conformité, performance, risques), (4) Rapport "
            "et recommandations. Les critères d\'audit peuvent être "
            "légaux (Code du Travail, CNPS), normatifs (ISO 30400 sur "
            "le management des RH), ou internes (procédures maison).",
      ),
      ResourceSection(
        title: '2. Domaines d\'audit et grille d\'évaluation',
        content: "L\'audit RH couvre plusieurs domaines interconnectés : "
            "l\'administration du personnel (contrats, dossiers, registres), "
            "la paie et les déclarations sociales (conformité CNPS, "
            "impôts), le recrutement (processus, non-discrimination), "
            "la formation (plan, évaluation, FAFP), les relations "
            "sociales (CSE, NAO, accords), et la performance RH "
            "(indicateurs, tableau de bord). Une grille d\'évaluation "
            "avec critères pondérés permet de calculer un score de "
            "maturité RH. Chaque écart donne lieu à une constatation "
            "d\'audit (conforme, écart mineur, écart majeur, observation).",
      ),
      ResourceSection(
        title: '3. Conduite des entretiens et collecte des données',
        content: "Les entretiens sont un outil clé de l\'audit RH : entretiens "
            "avec le DRH, les RRH, les managers opérationnels, les "
            "représentants du personnel, et les collaborateurs. Les "
            "techniques d\'entretien d\'audit (entretien semi-directif, "
            "technique des 5 pourquoi, confrontation des sources) "
            "permettent de recueillir des informations fiables. La "
            "triangulation des sources (documents + entretiens + observations) "
            "garantit la robustesse des constats. Le climat de confiance "
            "est essentiel pour la qualité des informations recueillies.",
      ),
      ResourceSection(
        title: '4. Rapport d\'audit et plan d\'action',
        content: "Le rapport d\'audit présente les constats organisés par "
            "domaine, avec une évaluation de la criticité (risque "
            "identifié) et de l\'urgence. Chaque recommandation doit "
            "être SMART : Spécifique, Mesurable, Atteignable, Réaliste, "
            "et Temporellement définie. Le plan d\'action qui en découle "
            "hiérarchise les actions par priorité (critique, important, "
            "souhaitable) et désigne des pilotes. Un comité de suivi "
            "trimestriel vérifie l\'avancement. L\'efficacité de l\'audit "
            "se mesure à la mise en œuvre des recommandations.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 9. Mobilité interne / Carrières
// ---------------------------------------------------------------------------
final HrTemplate mobiliteCarrieres = HrTemplate(
  id: 'mobilite_carrieres',
  title: 'Mobilité et carrières',
  description: 'Mobilité interne, parcours professionnels, GPEC individuelle',
  level: 'master',
  icon: 'transfer_within_a_station',
  role: "Vous êtes le DRH d\'un groupe hôtelier de 700 salariés (8 établissements en Afrique de l\'Ouest).",
  context: "Le groupe connaît une forte rotation dans les postes d\'encadrement "
      "intermédiaire (chefs de service, sous-directeurs). L\'analyse des "
      "entretiens de départ révèle que les salariés quittent l\'entreprise "
      "par manque de perspectives d\'évolution. Le CEO vous demande de "
      "mettre en place une politique de mobilité interne ambitieuse : "
      "bourse d\'emplois interne, parcours de carrière par métier, "
      "et dispositif de mobilité géographique entre les établissements "
      "des 4 pays de la zone. Le budget alloué est de 150 millions FCFA "
      "par an pour la mobilité et les parcours professionnels.",
  objectives: [
    'Concevoir une politique de mobilité interne attractive',
    'Définir des parcours de carrière pour chaque filière métier',
    'Mettre en place un dispositif de mobilité géographique',
    'Équilibrer aspirations individuelles et besoins opérationnels',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Dispositif de mobilité', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Parcours de carrière', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Aspects financiers et pratiques', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Communication et accompagnement', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_aide_mobilite',
      label: 'Budget aide à la mobilité',
      description: 'Budget annuel pour les aides à la mobilité géographique (logement, transport, installation)',
      type: DecisionType.currency,
      min: 20000000,
      max: 100000000,
      defaultValue: 50000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'taux_mobilite_cible',
      label: 'Taux de mobilité cible',
      description: '% de l\'effectif en mobilité chaque année',
      type: DecisionType.percentage,
      min: 5,
      max: 25,
      defaultValue: 12,
      step: 2,
    ),
    DecisionParam(
      id: 'duree_min_affectation',
      label: 'Durée minimale par poste',
      description: 'Durée minimale en mois avant de pouvoir postuler à une mobilité',
      type: DecisionType.integer,
      min: 12,
      max: 36,
      defaultValue: 24,
      step: 6,
    ),
    DecisionParam(
      id: 'prime_mobilite',
      label: 'Prime de mobilité',
      description: 'Montant de la prime unique versée en cas de mobilité géographique acceptée',
      type: DecisionType.currency,
      min: 500000,
      max: 3000000,
      defaultValue: 1500000,
      step: 250000,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_mobilite_interne',
      label: 'Taux de mobilité interne réalisé',
      unit: '%',
      description: '% de l\'effectif ayant changé de poste en interne dans l\'année',
    ),
    SuccessMetric(
      id: 'delai_tenue_poste',
      label: 'Délai moyen de tenue de poste',
      unit: 'mois',
      description: 'Ancienneté moyenne dans le poste avant mobilité',
    ),
    SuccessMetric(
      id: 'satisfaction_carriere',
      label: 'Satisfaction perspectives carrière',
      unit: '/100',
      description: 'Score de satisfaction des collaborateurs (enquête)',
    ),
  ],
  decisionPeriods: 4,
  rules: [
    '4 périodes = 2 ans (semestrielles)',
    'Un poste ouvert en interne doit rester publié 15 jours avant ouverture externe',
  ],
  constraints: [
    'Budget annuel mobilité = 150 millions FCFA',
    'Un salarié doit rester au moins 12 mois dans son poste avant de pouvoir postuler en interne',
    'La mobilité ne doit pas dégrader le taux d\'encadrement des établissements',
  ],
  resourceContent: ResourceContent(
    summary: "La mobilité interne est l\'ensemble des dispositifs permettant "
        "aux collaborateurs de changer de poste, de site, ou de métier "
        "au sein de la même entreprise. Elle est un levier majeur de "
        "fidélisation, de développement des compétences, et d\'adaptation "
        "aux mutations. Une politique de mobilité interne structurée "
        "comprend une bourse d\'emplois interne, des parcours de carrière "
        "par filière, des aides à la mobilité géographique, et un "
        "accompagnement personnalisé des collaborateurs.",
    keyConcepts: [
      'Mobilité interne',
      'Bourse d\'emplois interne',
      'Parcours professionnel',
      'Filière métier et passerelles',
      'Mobilité géographique et expatriation',
      'Entretien de carrière',
      'Bilan de compétences',
      'Coaching de carrière',
      'Mobilité fonctionnelle (changement de métier)',
      'Détachement et mise à disposition',
    ],
    sections: [
      ResourceSection(
        title: '1. Cadre de la politique de mobilité interne',
        content: "La politique de mobilité interne s\'inscrit dans le cadre "
            "légal : le Code du Travail prévoit des clauses de mobilité "
            "géographique et fonctionnelle dans les contrats. Elle doit "
            "être négociée avec les partenaires sociaux et formalisée "
            "dans un accord collectif ou une charte. La politique définit "
            "les règles : conditions d\'éligibilité, procédure de "
            "candidature, délais, aides accordées, et garanties de "
            "retour en cas d\'échec. La transparence sur les postes "
            "ouverts et les critères de sélection est essentielle.",
      ),
      ResourceSection(
        title: '2. Dispositifs opérationnels',
        content: "Les dispositifs de mobilité incluent : (1) la bourse "
            "d\'emplois interne (plateforme digitale listant tous les "
            "postes ouverts avant publication externe), (2) les "
            "parcours de carrière (schémas d\'évolution par filière "
            "métier avec jalons de compétences), (3) les passerelles "
            "entre métiers (conditions pour changer de filière), "
            "(4) le dispositif de mobilité géographique (aide au "
            "logement, prime d\'installation, accompagnement famille), "
            "et (5) l\'accompagnement individualisé (entretien de "
            "carrière, coaching, bilan de compétences).",
      ),
      ResourceSection(
        title: '3. Accompagnement des collaborateurs',
        content: "L\'accompagnement des collaborateurs dans leur projet de "
            "mobilité est essentiel à la réussite du dispositif. "
            "L\'entretien de carrière (distinct de l\'entretien annuel "
            "d\'évaluation) est l\'occasion d\'échanger sur les aspirations "
            "et de construire un plan de développement. Le bilan de "
            "compétences (réalisé par un prestataire externe agréé) "
            "permet d\'identifier les compétences transférables. Le "
            "coaching de carrière peut être proposé aux collaborateurs "
            "en réflexion ou en préparation de mobilité.",
      ),
      ResourceSection(
        title: '4. Mesure et pilotage de la mobilité',
        content: "L\'efficacité de la politique de mobilité se mesure par "
            "des indicateurs : taux de mobilité interne (cible 10-15% "
            "par an), délai de mobilité (temps entre la candidature et "
            "la prise de poste), taux de succès (période d\'essai validée), "
            "taux de rétention des mobiles (présence à 1 an), et "
            "satisfaction des mobiles et des managers d\'accueil. Le "
            "tableau de bord de la mobilité est examiné semestriellement "
            "en comité de direction. Les freins à la mobilité sont "
            "analysés et traités.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 10. Management interculturel
// ---------------------------------------------------------------------------
final HrTemplate managementInterculturel = HrTemplate(
  id: 'management_interculturel',
  title: 'Management interculturel',
  description: 'Équipes multiculturelles, expatriation, diversité culturelle',
  level: 'master',
  icon: 'language',
  role: "Vous êtes le DRH d\'une entreprise pétrolière de 900 salariés présente dans 8 pays africains.",
  context: "Le groupe, historiquement français, s\'est développé en Afrique "
      "avec une forte proportion de cadres expatriés (25% de l\'encadrement). "
      "Le CEO souhaite accélérer l\'africanisation des postes (passer de "
      "75% à 90% de cadres locaux d\'ici 3 ans) tout en préservant la "
      "qualité opérationnelle. Les équipes sont multiculturelles : "
      "Français, Ivoiriens, Sénégalais, Camerounais, et expatriés "
      "d\'autres pays africains. Les tensions culturelles apparaissent "
      "dans les relations hiérarchiques et le rapport au temps et à "
      "la prise de décision. Vous devez concevoir un programme de "
      "management interculturel et un plan d\'africanisation.",
  objectives: [
    'Diagnostiquer les différences culturelles et leurs impacts managériaux',
    'Concevoir un programme de formation interculturelle',
    'Élaborer un plan d\'africanisation des postes cadres',
    'Proposer des outils de pilotage de la diversité culturelle',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Diagnostic interculturel', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Plan d\'africanisation', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Programme de formation', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Indicateurs diversité', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_formation_interculturelle',
      label: 'Budget formation interculturelle',
      description: 'Budget annuel pour les programmes de formation interculturelle et accompagnement expatriés',
      type: DecisionType.currency,
      min: 15000000,
      max: 100000000,
      defaultValue: 40000000,
      step: 5000000,
    ),
    DecisionParam(
      id: 'taux_expatriation_cible',
      label: 'Taux d\'expatriation cible',
      description: '% de cadres expatriés dans l\'encadrement à horizon 3 ans',
      type: DecisionType.percentage,
      min: 5,
      max: 25,
      defaultValue: 15,
      step: 2,
    ),
    DecisionParam(
      id: 'duree_accompagnement_expat',
      label: 'Durée accompagnement expatriés',
      description: 'Durée en mois du programme d\'intégration pour les nouveaux expatriés',
      type: DecisionType.integer,
      min: 1,
      max: 12,
      defaultValue: 6,
      step: 1,
    ),
    DecisionParam(
      id: 'prime_expatriation',
      label: 'Prime d\'expatriation',
      description: 'Pourcentage du salaire de base versé comme prime d\'expatriation',
      type: DecisionType.percentage,
      min: 10,
      max: 50,
      defaultValue: 30,
      step: 5,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_africanisation',
      label: 'Taux d\'africanisation des cadres',
      unit: '%',
      description: '% de cadres dirigeants locaux',
    ),
    SuccessMetric(
      id: 'score_inclusion',
      label: 'Score d\'inclusion perçue',
      unit: '/100',
      description: 'Score d\'inclusion des collaborateurs (enquête diversité)',
    ),
    SuccessMetric(
      id: 'taux_reussite_expat',
      label: 'Taux de réussite des expatriations',
      unit: '%',
      description: '% d\'expatriations menées à terme sans rapatriement anticipé',
    ),
  ],
  decisionPeriods: 3,
  rules: [
    '3 périodes = 3 ans (annuelles)',
    'Chaque période = 1 plan d\'africanisation + 1 cohorte de formation',
  ],
  constraints: [
    'La réduction du taux d\'expatriation ne peut excéder 5% par an',
    'Au moins 80% des postes d\'encadrement local doivent avoir un plan de transfert de compétences',
  ],
  resourceContent: ResourceContent(
    summary: "Le management interculturel est la discipline qui étudie et "
        "optimise le fonctionnement des équipes multiculturelles. Dans le "
        "contexte des entreprises africaines, il est essentiel pour gérer "
        "la diversité culturelle entre expatriés et locaux, entre "
        "différentes ethnies et nationalités, et entre générations. "
        "Les modèles de référence (Hofstede, Trompenaars, Hall) "
        "permettent d\'analyser les différences culturelles : rapport "
        "à la hiérarchie, au temps, à l\'incertitude, et à la communication.",
    keyConcepts: [
      'Dimensions culturelles (Hofstede)',
      'Communication interculturelle',
      'Choc culturel et adaptation',
      'Expatriation et rapatriement',
      'Africanisation des cadres',
      'Diversité et inclusion',
      'Management de proximité en contexte africain',
      'Transfert de compétences Nord-Sud et Sud-Sud',
      'Mentorat interculturel',
      'Négociation interculturelle',
    ],
    sections: [
      ResourceSection(
        title: '1. Fondements du management interculturel',
        content: "Le management interculturel repose sur la compréhension des "
            "dimensions culturelles identifiées par Geert Hofstede : "
            "distance hiérarchique (rapport à l\'autorité), contrôle de "
            "l\'incertitude (besoin de règles), individualisme vs "
            "collectivisme, masculinité vs féminité, et orientation long "
            "terme. En Afrique, la distance hiérarchique est généralement "
            "élevée, le collectivisme prédomine, et le rapport au temps "
            "est plus flexible (concept d'« African Time »). La communication "
            "est souvent indirecte et le contexte relationnel prime.",      ),
      ResourceSection(
        title: '2. Gestion des équipes multiculturelles',
        content: "Les équipes multiculturelles sont plus créatives mais plus "
            "complexes à manager. Les défis incluent : les différences "
            "de styles de communication (direct vs indirect), les "
            "attentes vis-à-vis du leader (directif vs participatif), "
            "et les conflits de valeurs. Les bonnes pratiques incluent : "
            "(1) établir des règles de fonctionnement explicites, "
            "(2) valoriser la diversité des perspectives, (3) former "
            "les managers à l\'intelligence culturelle (CQ), "
            "(4) créer des rituels d\'équipe inclusifs.",
      ),
      ResourceSection(
        title: '3. Politique d\'expatriation et d\'africanisation',
        content: "La politique d\'expatriation comprend le recrutement, la "
            "préparation (formation interculturelle, administrative), "
            "l\'intégration (accueil, logement, scolarité), le suivi "
            "(coaching, évaluation), et le rapatriement. L\'africanisation "
            "est un processus stratégique de transfert progressif des "
            "responsabilités aux cadres locaux. Elle repose sur : le "
            "repérage des potentiels locaux, le mentorat par les "
            "expatriés, la formation technique et managériale, et "
            "l\'accompagnement à la prise de poste.",
      ),
      ResourceSection(
        title: '4. Accompagnement et indicateurs',
        content: "L\'accompagnement interculturel comprend des formations "
            "obligatoires pour les expatriés et leurs conjoints, des "
            "sessions de sensibilisation pour les équipes locales, et "
            "un réseau de mentors binationaux. Les indicateurs clés "
            "sont le taux de réussite des expatriations, le taux "
            "d\'africanisation, le score d\'inclusion (enquête), le "
            "taux de rétention des cadres locaux, et la proportion de "
            "femmes dans l\'encadrement.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 11. RSE et RH — Égalité, diversité, QVT
// ---------------------------------------------------------------------------
final HrTemplate rseRh = HrTemplate(
  id: 'rse_rh',
  title: 'RSE et RH',
  description: 'Égalité, diversité, QVT, responsabilité sociale',
  level: 'master',
  icon: 'eco',
  role: "Vous êtes le DRH d\'une entreprise de grande distribution de 500 salariés.",
  context: "Le groupe est critiqué par la presse et les ONG pour ses "
      "pratiques sociales : inégalités salariales hommes-femmes, faible "
      "représentation des femmes dans l\'encadrement (12%), et conditions "
      "de travail difficiles dans les entrepôts. Le CEO, soucieux de "
      "l\'image de marque et de la réglementation à venir, vous demande "
      "un plan RSE RH complet avec des objectifs chiffrés. Vous devez "
      "traiter l\'égalité professionnelle, la diversité, la qualité de "
      "vie au travail (QVT), et l\'impact social de l\'entreprise. Le "
      "budget alloué est de 200 millions FCFA par an. La pression "
      "médiatique est forte et les résultats attendus dans 18 mois.",
  objectives: [
    'Réaliser un diagnostic RSE RH complet',
    'Élaborer un plan d\'action égalité et diversité avec objectifs chiffrés',
    'Proposer des actions QVT et d\'amélioration des conditions de travail',
    'Définir des indicateurs de reporting RSE (ESG)',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Diagnostic RSE RH', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Plan égalité/diversité', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Actions QVT', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Reporting ESG', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_egalite',
      label: 'Budget égalité et diversité',
      description: 'Budget annuel pour les actions égalité femmes-hommes et diversité',
      type: DecisionType.currency,
      min: 20000000,
      max: 80000000,
      defaultValue: 40000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'cible_femmes_cadres',
      label: 'Cible femmes cadres',
      description: '% cible de femmes dans l\'encadrement à 3 ans',
      type: DecisionType.percentage,
      min: 20,
      max: 50,
      defaultValue: 30,
      step: 5,
    ),
    DecisionParam(
      id: 'budget_qvt',
      label: 'Budget QVT',
      description: 'Budget annuel pour les actions qualité de vie au travail',
      type: DecisionType.currency,
      min: 20000000,
      max: 100000000,
      defaultValue: 50000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'index_egalite_cible',
      label: 'Index égalité cible',
      description: 'Score cible de l\'index égalité professionnelle (sur 100)',
      type: DecisionType.integer,
      min: 60,
      max: 100,
      defaultValue: 85,
      step: 5,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'index_egalite',
      label: 'Index égalité professionnelle',
      unit: '/100',
      description: 'Score global d\'égalité femmes-hommes',
    ),
    SuccessMetric(
      id: 'taux_femmes_cadres',
      label: 'Taux de femmes cadres',
      unit: '%',
      description: '% de femmes dans les postes d\'encadrement',
    ),
    SuccessMetric(
      id: 'score_qvt',
      label: 'Score QVT',
      unit: '/100',
      description: 'Score de qualité de vie au travail (enquête collaborateurs)',
    ),
  ],
  decisionPeriods: 3,
  rules: [
    '3 périodes = 3 ans (annuelles)',
    'L\'index égalité est calculé et publié chaque année',
  ],
  constraints: [
    'Budget RSE RH total = 200 millions FCFA/an',
    'L\'index égalité doit progresser d\'au moins 5 points par an',
    'Le rapport RSE (ESG) est obligatoire à partir de la période 2',
  ],
  resourceContent: ResourceContent(
    summary: "La Responsabilité Sociale des Entreprises (RSE) appliquée aux "
        "Ressources Humaines couvre les thématiques d\'égalité professionnelle, "
        "de diversité et inclusion, de qualité de vie au travail (QVT), "
        "et d\'impact social. C\'est un levier d\'attractivité, d\'engagement "
        "et de performance durable. Le reporting ESG (Environnemental, "
        "Social, Gouvernance) devient obligatoire pour les grandes "
        "entreprises et les critères sociaux pèsent de plus en plus "
        "dans la notation extra-financière.",
    keyConcepts: [
      'RSE — Responsabilité Sociale des Entreprises',
      'Égalité professionnelle femmes-hommes',
      'Diversité et inclusion',
      'QVT — Qualité de Vie au Travail',
      'Reporting ESG',
      'Index d\'égalité',
      'Label Diversité / Égalité',
      'Non-discrimination et recrutement inclusif',
      'Handicap et emploi',
      'Bilans carbone social et mobilité durable',
    ],
    sections: [
      ResourceSection(
        title: '1. Cadre légal et référentiels RSE RH',
        content: "La RSE RH s\'appuie sur des textes nationaux et internationaux : "
            "la loi sur l\'égalité professionnelle (loi 2019-570 en Côte "
            "d\'Ivoire), les principes directeurs de l\'OCDE, les normes "
            "ISO 26000 (responsabilité sociétale) et SA 8000 (conditions "
            "de travail). La directive européenne CSRD impose aux "
            "entreprises un reporting extra-financier détaillé sur les "
            "critères ESG. En Afrique, la RSE est souvent portée par "
            "les filiales de groupes internationaux mais devient un "
            "enjeu de compétitivité pour les entreprises locales.",
      ),
      ResourceSection(
        title: '2. Égalité professionnelle et diversité',
        content: "L\'égalité professionnelle se mesure via des indicateurs "
            "structurels : écart de rémunération, taux de promotion, "
            "mixité des métiers, et accès à la formation. L\'Index "
            "d\'égalité (sur 100 points) est calculé sur 5 indicateurs "
            "et doit être publié annuellement. Un score inférieur à "
            "75/100 déclenche des mesures correctives obligatoires. "
            "La diversité va au-delà du genre : elle inclut l\'origine "
            "ethnique, le handicap, l\'âge, et les orientations "
            "sexuelles. Les politiques de diversité les plus efficaces "
            "sont celles qui fixent des objectifs chiffrés.",
      ),
      ResourceSection(
        title: '3. Qualité de Vie au Travail (QVT)',
        content: "La QVT recouvre les conditions dans lesquelles les salariés "
            "exercent leur travail : conditions physiques (ergonomie, "
            "sécurité), organisation du travail (autonomie, charge), "
            "relations sociales (climat, reconnaissance), et équilibre "
            "vie pro/perso (horaires, télétravail). La démarche QVT "
            "est co-construite avec les collaborateurs via des groupes "
            "de travail et un questionnaire d\'évaluation. Les actions "
            "QVT typiques incluent : flexibilité des horaires, "
            "télétravail partiel, cellule d\'écoute psychologique, "
            "espaces de convivialité, et programme de reconnaissance.",
      ),
      ResourceSection(
        title: '4. Reporting ESG et pilotage RSE',
        content: "Le reporting social (ESG Social) doit présenter des "
            "indicateurs standardisés : effectifs et turn-over, "
            "formation, égalité, santé et sécurité, dialogue social, "
            "et diversité. Le Global Reporting Initiative (GRI) est "
            "le référentiel le plus utilisé. En Afrique, les "
            "entreprises cotées à la BRVM doivent publier un rapport "
            "RSE annuel. Le pilotage RSE RH est assuré par un comité "
            "RSE trimestriel qui suit les indicateurs, valide les "
            "plans d\'action, et prépare le reporting.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 12. Contrôle de gestion social
// ---------------------------------------------------------------------------
final HrTemplate controleGestionSocial = HrTemplate(
  id: 'controle_gestion_social',
  title: 'Contrôle de gestion social',
  description: 'Budget RH, tableaux de bord, pilotage financier social',
  level: 'master',
  icon: 'bar_chart',
  role: "Vous êtes le DRH d\'une entreprise manufacturière de 400 salariés.",
  context: "L\'entreprise traverse une phase de croissance rapide (+25% de "
      "l\'effectif en 2 ans) mais la fonction RH ne dispose pas d\'outils "
      "de pilotage financier structurés. Le DAF vous demande de mettre "
      "en place un contrôle de gestion social (budget RH, reporting "
      "mensuel, analyse des écarts). Vous devez concevoir un tableau "
      "de bord avec des indicateurs financiers et sociaux, budgétiser "
      "la masse salariale sur 3 ans, et proposer un processus de "
      "revue budgétaire mensuelle. Le budget masse salariale actuel "
      "est de 3,2 milliards FCFA.",
  objectives: [
    'Mettre en place un tableau de bord de pilotage social',
    'Budgétiser la masse salariale et les effectifs sur 3 ans',
    'Concevoir un processus de suivi budgétaire mensuel',
    'Développer des outils d\'analyse des écarts et de prévision',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Architecture du contrôle de gestion', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Budget et prévisions', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Tableaux de bord et indicateurs', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Processus et gouvernance', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_augmentation_ms',
      label: 'Augmentation masse salariale',
      description: '% d\'augmentation de la masse salariale autorisé sur l\'année',
      type: DecisionType.percentage,
      min: 2,
      max: 12,
      defaultValue: 6,
      step: 1,
    ),
    DecisionParam(
      id: 'budget_recrutement_annee',
      label: 'Budget recrutement',
      description: 'Budget annuel pour le recrutement (hors salaires)',
      type: DecisionType.currency,
      min: 20000000,
      max: 150000000,
      defaultValue: 60000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'effectif_cible_annee',
      label: 'Effectif cible fin d\'année',
      description: 'Nombre de salariés visé en fin d\'année',
      type: DecisionType.integer,
      min: 400,
      max: 500,
      defaultValue: 450,
      step: 10,
    ),
    DecisionParam(
      id: 'frequence_reporting',
      label: 'Fréquence du reporting',
      description: 'Nombre de reports par an (12 = mensuel, 4 = trimestriel)',
      type: DecisionType.integer,
      min: 4,
      max: 12,
      defaultValue: 12,
      step: 4,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_ecart_budget',
      label: 'Écart budgétaire',
      unit: '%',
      description: 'Écart entre budget prévu et réalisé',
    ),
    SuccessMetric(
      id: 'ratio_masse_salariale',
      label: 'Ratio masse salariale / CA',
      unit: '%',
      description: 'Poids de la masse salariale dans le chiffre d\'affaires',
    ),
    SuccessMetric(
      id: 'delai_reporting',
      label: 'Délai de clôture sociale',
      unit: 'jours',
      description: 'Nombre de jours pour produire le reporting RH mensuel',
    ),
  ],
  decisionPeriods: 4,
  rules: [
    '4 périodes = 12 mois (trimestrielles)',
    'Chaque période : vote du budget annuel (période 1), suivi et ajustements (périodes 2-4)',
  ],
  constraints: [
    'Ratio masse salariale / chiffre d\'affaires plafonné à 45%',
    'Le recrutement net ne peut excéder +20% de l\'effectif par an',
  ],
  resourceContent: ResourceContent(
    summary: "Le contrôle de gestion social (ou contrôle de gestion RH) est "
        "l\'ensemble des outils et processus qui permettent de piloter la "
        "performance financière et sociale de la fonction RH. Il couvre "
        "la budgétisation de la masse salariale, le suivi des effectifs, "
        "l\'analyse des écarts, et le reporting aux directions. C\'est "
        "un outil de dialogue entre la DRH et la DAF pour arbitrer les "
        "décisions d\'investissement RH et maîtriser les coûts tout en "
        "atteignant les objectifs de développement des compétences.",
    keyConcepts: [
      'Contrôle de gestion social',
      'Masse salariale et effet de structure',
      'Budget RH et suivi budgétaire',
      'Reporting RH mensuel',
      'Effet Noria',
      'Glissement Vieillesse Technicité (GVT)',
      'Analyse des écarts',
      'Tableau de bord prospectif RH',
      'Clôture sociale et paie',
      'Benchmark de productivité RH',
    ],
    sections: [
      ResourceSection(
        title: '1. Fondamentaux du contrôle de gestion social',
        content: "Le contrôle de gestion social se structure autour de trois "
            "piliers : la gestion budgétaire (budget masse salariale, "
            "suivi des effectifs), le reporting (tableaux de bord "
            "mensuels, analyse des écarts), et l\'analyse prospective "
            "(prévisions 3-5 ans). Les concepts clés incluent l\'effectif "
            "permanent vs temporaire, le GVT (Glissement, Vieillesse, "
            "Technicité), l\'effet Noria (remplacement des seniors par "
            "des juniors), et la masse salariale totale.",
      ),
      ResourceSection(
        title: '2. Budgétisation de la masse salariale',
        content: "La budgétisation de la masse salariale s\'effectue en "
            "plusieurs étapes : (1) projection des effectifs par "
            "catégorie et service, (2) application des augmentations "
            "collectives et individuelles, (3) intégration du GVT "
            "et de l\'effet Noria, (4) calcul des charges sociales et "
            "taxes, (5) intégration des éléments exceptionnels "
            "(primes, heures supplémentaires). Le budget est construit "
            "avec les managers opérationnels et validé par la DAF.",
      ),
      ResourceSection(
        title: '3. Tableaux de bord et reporting RH',
        content: "Le tableau de bord RH mensuel présente les indicateurs "
            "clés : effectif, masse salariale (réalisé vs budget), "
            "absentéisme, turnover, coût par recrutement, et dépenses "
            "de formation. L\'analyse des écarts (budget vs réalisé) "
            "avec commentaires explicatifs est le cœur du reporting. "
            "La clôture sociale (arrêté de la paie) doit être produite "
            "dans les 5 jours ouvrés après la fin de mois.",
      ),
      ResourceSection(
        title: '4. Pilotage et gouvernance',
        content: "Le pilotage budgétaire RH s\'inscrit dans le cycle de "
            "gestion de l\'entreprise : revue budgétaire mensuelle "
            "entre DRH et DAF, comité des investissements RH "
            "trimestriel, et arbitrage annuel du budget. Les outils "
            "de simulation (scénarios masse salariale, what-if) sont "
            "essentiels pour éclairer les décisions. Le contrôle de "
            "gestion social permet d\'évaluer le retour sur investissement "
            "des décisions RH et de démontrer la contribution de la "
            "fonction RH à la performance de l\'entreprise.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 13. Droit social avancé — PSE, restructuration
// ---------------------------------------------------------------------------
final HrTemplate droitSocialAvance = HrTemplate(
  id: 'droit_social_avance',
  title: 'Droit social avancé',
  description: 'PSE, restructuration, contentieux prud\'homal',
  level: 'master',
  icon: 'gavel',
  role: "Vous êtes le DRH d\'une entreprise industrielle de 350 salariés mise en difficulté par la crise économique.",
  context: "L\'entreprise doit supprimer 80 postes dans le cadre d\'une "
      "restructuration économique. Vous devez élaborer un Plan de "
      "Sauvegarde de l\'Emploi (PSE) conforme au Code du Travail et "
      "négocier avec les syndicats et l\'Inspection du Travail. Le "
      "budget social alloué est de 500 millions FCFA. Parallèlement, "
      "plusieurs salariés licenciés ont saisi le Tribunal du Travail. "
      "Vous devez gérer les contentieux prud\'homaux tout en "
      "maintenant un climat social acceptable avec les salariés "
      "restants. Le contexte médiatique est tendu et le Ministère "
      "du Travail suit le dossier.",
  objectives: [
    'Concevoir un PSE conforme à la réglementation sociale',
    'Définir les critères d\'ordre des licenciements',
    'Proposer des mesures d\'accompagnement et de reclassement',
    'Gérer les contentieux prud\'homaux',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Conformité juridique du PSE', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Mesures d\'accompagnement', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Gestion des contentieux', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Communication de crise', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_accompagnement',
      label: 'Budget accompagnement PSE',
      description: 'Budget total pour les mesures d\'accompagnement (reclassement, formation, indemnités supra-légales)',
      type: DecisionType.currency,
      min: 100000000,
      max: 500000000,
      defaultValue: 300000000,
      step: 25000000,
    ),
    DecisionParam(
      id: 'delai_pse',
      label: 'Délai de mise en œuvre',
      description: 'Durée en mois du PSE (information-consultation + mise en œuvre)',
      type: DecisionType.integer,
      min: 3,
      max: 12,
      defaultValue: 6,
      step: 1,
    ),
    DecisionParam(
      id: 'indemnite_supra_legale',
      label: 'Indemnité supra-légale',
      description: 'Montant supplémentaire au-delà de l\'indemnité légale de licenciement (en mois de salaire)',
      type: DecisionType.integer,
      min: 0,
      max: 6,
      defaultValue: 2,
      step: 1,
    ),
    DecisionParam(
      id: 'budget_reclassement',
      label: 'Budget reclassement externe',
      description: 'Budget pour le reclassement externe (outplacement, formation, aide à la création d\'entreprise)',
      type: DecisionType.currency,
      min: 50000000,
      max: 200000000,
      defaultValue: 100000000,
      step: 10000000,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'taux_reclassement',
      label: 'Taux de reclassement',
      unit: '%',
      description: '% de salariés reclassés en interne ou en externe',
    ),
    SuccessMetric(
      id: 'cout_contentieux',
      label: 'Coût des contentieux',
      unit: 'FCFA',
      description: 'Montant total des condamnations prud\'homales',
    ),
    SuccessMetric(
      id: 'delai_procedure',
      label: 'Délai de procédure',
      unit: 'mois',
      description: 'Durée totale de la procédure PSE',
    ),
  ],
  decisionPeriods: 3,
  rules: [
    '3 périodes = phases du PSE : information-consultation (P1), mise en œuvre (P2), suivi (P3)',
    'Le PSE doit être validé par l\'Inspection du Travail',
  ],
  constraints: [
    'Budget social total = 500 millions FCFA',
    'Le PSE doit respecter l\'ordre des licenciements défini par le Code du Travail',
    'Au moins 30% des salariés concernés doivent bénéficier d\'une mesure de reclassement',
  ],
  resourceContent: ResourceContent(
    summary: "Le Plan de Sauvegarde de l\'Emploi (PSE) est une procédure "
        "obligatoire pour les entreprises d\'au moins 50 salariés qui "
        "envisagent un licenciement collectif d\'au moins 10 salariés. "
        "Il doit prévoir des mesures pour éviter les licenciements ou "
        "en limiter le nombre (reclassement interne, formation, "
        "congés de conversion) et des mesures d\'accompagnement pour "
        "les salariés licenciés (indemnités supra-légales, outplacement, "
        "aide à la création d\'entreprise). Le PSE est soumis à la "
        "validation de l\'Inspection du Travail.",
    keyConcepts: [
      'PSE — Plan de Sauvegarde de l\'Emploi',
      'Licenciement économique',
      'Critères d\'ordre des licenciements',
      'Obligation de reclassement',
      'Indemnités légales et supra-légales',
      'Contrat de sécurisation professionnelle (CSP)',
      'Contentieux prud\'homal',
      'Inspection du Travail et DIRECCTE',
      'Plan de départs volontaires',
      'Surenchère sociale et médiation',
    ],
    sections: [
      ResourceSection(
        title: '1. Cadre juridique du licenciement économique',
        content: "Le licenciement économique est motivé par des difficultés "
            "économiques, des mutations technologiques, ou une "
            "réorganisation nécessaire à la sauvegarde de l\'entreprise. "
            "Dans le Code du Travail malien et OHADA, l\'employeur "
            "doit démontrer la réalité et la gravité des difficultés. "
            "La procédure comprend : convocation aux entretiens "
            "préalables, notification, et respect d\'un préavis. "
            "Pour les licenciements collectifs, l\'obligation "
            "d\'élaborer un PSE s\'applique dès 10 salariés dans "
            "les entreprises de 50 salariés et plus.",
      ),
      ResourceSection(
        title: '2. Élaboration et contenu du PSE',
        content: "Le PSE comprend obligatoirement : (1) le rapport "
            "justificatif des difficultés économiques, (2) le projet "
            "de licenciement (postes supprimés, critères d\'ordre), "
            "(3) le plan de reclassement interne (postes disponibles, "
            "mobilité), (4) les mesures de formation et d\'adaptation, "
            "(5) les mesures de soutien à la création d\'entreprise, "
            "et (6) les indemnités supra-légales. Le PSE est élaboré "
            "en concertation avec le CSE et les syndicats.",
      ),
      ResourceSection(
        title: '3. Mesures d\'accompagnement et reclassement',
        content: "Les mesures d\'accompagnement sont le cœur du PSE. Le "
            "reclassement interne est prioritaire : identification "
            "des postes disponibles, mobilité géographique, et "
            "réduction du temps de travail. Le reclassement externe "
            "peut inclure un congé de reclassement (6 à 12 mois "
            "avec formation), une aide à la création d\'entreprise, "
            "ou un outplacement. Le contrat de sécurisation "
            "professionnelle (CSP) permet au salarié de bénéficier "
            "d\'un accompagnement renforcé et d\'une allocation spécifique.",
      ),
      ResourceSection(
        title: '4. Contentieux prud\'homaux et prévention',
        content: "Les contentieux prud\'homaux portent sur la régularité "
            "de la procédure, le bien-fondé du motif économique, et "
            "le montant des indemnités. La prévention passe par une "
            "procédure irréprochable, une information transparente "
            "des représentants du personnel, et des offres de "
            "reclassement sérieuses. La médiation par l\'Inspection "
            "du Travail peut éviter une partie des contentieux. "
            "Les risques prud\'homaux doivent être provisionnés "
            "dans les comptes de l\'entreprise.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 14. HR Analytics — Data RH et modélisation prédictive
// ---------------------------------------------------------------------------
final HrTemplate hrAnalytics = HrTemplate(
  id: 'hr_analytics',
  title: 'HR Analytics',
  description: 'Data RH, predictive modeling, people analytics',
  level: 'master',
  icon: 'analytics',
  role: "Vous êtes le DRH d\'une entreprise de services financiers de 600 salariés.",
  context: "La direction générale souhaite passer d\'un RH intuitif à un "
      "RH data-driven. Vous devez mettre en place une cellule HR "
      "Analytics pour exploiter les données RH (paie, recrutement, "
      "formation, évaluation, turnover) et produire des insights "
      "prédictifs. Le SIRH est en place mais les données sont "
      "éparpillées et de qualité inégale. Vous devez définir le "
      "périmètre des analytics à développer, les outils à déployer "
      "(BI, machine learning), et les compétences de l\'équipe. "
      "Le budget d\'investissement est de 150 millions FCFA. "
      "Des questions de confidentialité et d\'éthique des données "
      "RH se posent, notamment pour les modèles prédictifs.",
  objectives: [
    'Définir le périmètre et la roadmap HR Analytics',
    'Mettre en place un datawarehouse RH et des tableaux de bord avancés',
    'Développer des modèles prédictifs (turnover, performance, potentiel)',
    'Garantir l\'éthique et la conformité des traitements de données RH',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Stratégie data RH', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Modèles et algorithmes', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Qualité et gouvernance des données', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Éthique et conformité', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_datawarehouse',
      label: 'Budget datawarehouse RH',
      description: 'Investissement dans l\'infrastructure data RH (stockage, ETL, BI)',
      type: DecisionType.currency,
      min: 30000000,
      max: 100000000,
      defaultValue: 60000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'modele_predictif',
      label: 'Type de modèle prédictif',
      description: '0 = Descriptive, 50 = Diagnostique, 100 = Prédictive (ML)',
      type: DecisionType.percentage,
      min: 0,
      max: 100,
      defaultValue: 50,
      step: 50,
    ),
    DecisionParam(
      id: 'taille_equipe_analytics',
      label: 'Taille équipe Analytics',
      description: 'Nombre de personnes dédiées à la cellule HR Analytics',
      type: DecisionType.integer,
      min: 1,
      max: 8,
      defaultValue: 3,
      step: 1,
    ),
    DecisionParam(
      id: 'frequence_reporting_data',
      label: 'Fréquence des analyses',
      description: 'Nombre de rapports analytics par mois',
      type: DecisionType.integer,
      min: 1,
      max: 12,
      defaultValue: 4,
      step: 1,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'maturite_data',
      label: 'Indice de maturité data RH',
      unit: '/100',
      description: 'Niveau de maturité de la démarche analytics',
    ),
    SuccessMetric(
      id: 'precision_modele',
      label: 'Précision des modèles prédictifs',
      unit: '%',
      description: 'Taux de précision des modèles de prédiction du turnover',
    ),
    SuccessMetric(
      id: 'taux_utilisation_insights',
      label: 'Taux d\'utilisation des insights',
      unit: '%',
      description: '% de décisions RH s\'appuyant sur des données analytics',
    ),
  ],
  decisionPeriods: 4,
  rules: [
    '4 périodes = 2 ans (semestrielles)',
    'Période 1 : cadrage et datawarehouse, Périodes 2-3 : développement des modèles, Période 4 : déploiement',
  ],
  constraints: [
    'Budget total HR Analytics = 150 millions FCFA sur 2 ans',
    'Les modèles prédictifs doivent être conformes à la réglementation sur la protection des données',
    'Aucun algorithme ne peut prendre de décision définitive sans validation humaine',
  ],
  resourceContent: ResourceContent(
    summary: "Le HR Analytics est l\'application des techniques d\'analyse de "
        "données et de machine learning aux données RH pour produire "
        "des insights actionnables. Il couvre l\'analytique descriptive "
        "(ce qui s\'est passé), l\'analytique diagnostique (pourquoi), "
        "l\'analytique prédictive (ce qui va se passer), et l\'analytique "
        "prescriptive (que faire). Les cas d\'usage incluent la "
        "prédiction du turnover, l\'identification des talents, "
        "l\'optimisation des recrutements, et l\'analyse de l\'engagement.",
    keyConcepts: [
      'People Analytics',
      'Datawarehouse RH et ETL',
      'BI — Business Intelligence RH',
      'Machine Learning et RH',
      'Prédiction du turnover',
      'Analyse de survie (cohortes)',
      'Natural Language Processing (CV analyse)',
      'Network Analysis (organisation informelle)',
      'Data governance et qualité des données',
      'Éthique de l\'IA en RH (biais algorithmiques)',
    ],
    sections: [
      ResourceSection(
        title: '1. Les niveaux de maturité du HR Analytics',
        content: "La maturité analytics d\'une fonction RH se mesure sur "
            "quatre niveaux : (1) Reporting réactif — tableaux de bord "
            "de base (effectifs, turnover, masse salariale), "
            "(2) Analytique descriptive — analyses ad hoc, segments, "
            "tendances, (3) Analytique prédictive — modèles statistiques "
            "et ML pour anticiper les comportements (départs, "
            "performance), (4) Analytique prescriptive — recommandations "
            "automatisées et A/B testing RH. Peu d\'entreprises "
            "dépassent le niveau 2.",
      ),
      ResourceSection(
        title: '2. Cas d\'usage et modèles prédictifs',
        content: "Les cas d\'usage les plus fréquents du HR Analytics sont : "
            "la prédiction du risque de départ (modèle de survie, "
            "random forest, régression logistique), l\'identification "
            "des profils à fort potentiel, la performance prédictive "
            "des recrutements, l\'optimisation des parcours de formation, "
            "et la détection des risques psychosociaux. Les modèles "
            "sont entraînés sur les données historiques et validés "
            "par des tests statistiques (AUC, précision, rappel).",
      ),
      ResourceSection(
        title: '3. Infrastructure et gouvernance des données',
        content: "La mise en place d\'un datawarehouse RH nécessite : "
            "l\'extraction des données des différents systèmes (SIRH, "
            "paie, ATS, LMS), le nettoyage et la standardisation, "
            "la modélisation (schéma en étoile), et la mise à "
            "disposition via des outils de visualisation (Power BI, "
            "Tableau, Metabase). La gouvernance inclut la définition "
            "des rôles (data owner, data steward), les règles de "
            "qualité, la sécurité, et la conformité RGPD.",
      ),
      ResourceSection(
        title: '4. Éthique et biais algorithmiques',
        content: "L\'utilisation d\'algorithmes en RH soulève des questions "
            "éthiques majeures : les biais historiques (data bias) "
            "peuvent être reproduits voire amplifiés par les modèles "
            "(discrimination genrée, ethnique). Les principes d\'une "
            "IA RH responsable incluent : la transparence, "
            "l\'explicabilité (comprendre pourquoi une décision "
            "algorithmique est prise), l\'équité (audit régulier des "
            "biais), et la supervision humaine. Un comité d\'éthique "
            "des données RH doit valider tout modèle avant déploiement.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 15. Gestion des crises RH — Plan social, attrition massive
// ---------------------------------------------------------------------------
final HrTemplate gestionCrisesRh = HrTemplate(
  id: 'gestion_crises_rh',
  title: 'Gestion des crises RH',
  description: 'Plan social, attrition massive, communication de crise',
  level: 'master',
  icon: 'warning',
  role: "Vous êtes le DRH d\'une entreprise aérienne de 800 salariés confrontée à une crise majeure.",
  context: "La pandémie et la hausse du carburant ont fait chuter le "
      "trafic de 60%. L\'entreprise doit se restructurer en urgence : "
      "200 suppressions de postes sont envisagées, la trésorerie ne "
      "tient plus que 6 mois. Parallèlement, un mouvement social "
      "spontané (sans syndicat) paralyse les opérations depuis 48h. "
      "Le CEO vous donne les pleins pouvoirs pour gérer la crise RH. "
      "Vous devez élaborer un plan de crise en 3 phases : court "
      "terme (gestion de l\'urgence sociale), moyen terme "
      "(restructuration), long terme (rebond). La pression "
      "médiatique est immense et le gouvernement menace de "
      "nationaliser la compagnie.",
  objectives: [
    'Gérer la crise sociale immédiate et reprendre le dialogue',
    'Concevoir un plan de sauvegarde de l\'emploi en urgence',
    'Maintenir l\'engagement des salariés restants',
    'Préparer la phase de rebond post-crise',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Gestion de l\'urgence', maxScore: 10, coefficient: 3),
    CriteriaDef(name: 'Plan de restructuration', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Communication de crise', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Plan de rebond', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_urgence_sociale',
      label: 'Budget urgence sociale',
      description: 'Budget immédiat pour mesures d\'urgence (primes de départ, médiation)',
      type: DecisionType.currency,
      min: 50000000,
      max: 400000000,
      defaultValue: 200000000,
      step: 25000000,
    ),
    DecisionParam(
      id: 'delai_plan_social',
      label: 'Délai du plan social',
      description: 'Nombre de mois pour mettre en œuvre le plan social',
      type: DecisionType.integer,
      min: 1,
      max: 6,
      defaultValue: 3,
      step: 1,
    ),
    DecisionParam(
      id: 'budget_retenion_critiques',
      label: 'Budget rétention talents critiques',
      description: 'Budget pour retenir les compétences critiques nécessaires au rebond',
      type: DecisionType.currency,
      min: 20000000,
      max: 150000000,
      defaultValue: 60000000,
      step: 10000000,
    ),
    DecisionParam(
      id: 'mesure_chomage_partiel',
      label: 'Mesure chômage partiel',
      description: '0 = Pas de chômage partiel, 50 = Chômage partiel 50%, 100 = Chômage partiel total',
      type: DecisionType.percentage,
      min: 0,
      max: 100,
      defaultValue: 50,
      step: 25,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'cout_total_crise',
      label: 'Coût total de la crise',
      unit: 'FCFA',
      description: 'Coût financier total (départs, contentieux, communication)',
    ),
    SuccessMetric(
      id: 'delai_sortie_crise',
      label: 'Délai de sortie de crise',
      unit: 'mois',
      description: 'Temps nécessaire pour stabiliser la situation sociale',
    ),
    SuccessMetric(
      id: 'retention_critiques',
      label: 'Rétention des talents critiques',
      unit: '%',
      description: '% des talents identifiés comme critiques encore présents après la crise',
    ),
  ],
  decisionPeriods: 3,
  rules: [
    '3 périodes = 3 phases : Urgence (P1 - 1 mois), Restructuration (P2 - 3 mois), Rebond (P3 - 6 mois)',
    'Chaque période a un budget limité et des objectifs spécifiques',
  ],
  constraints: [
    'Trésorerie restante = 2 milliards FCFA (toutes fonctions confondues)',
    'Le mouvement social doit être résolu en moins de 72h (période 1)',
    'La rétention des talents critiques est prioritaire (ne pas perdre plus de 10%)',
  ],
  resourceContent: ResourceContent(
    summary: "La gestion des crises RH est une compétence stratégique pour "
        "faire face aux situations exceptionnelles : plan social massif, "
        "attrition soudaine, conflit social aigu, scandale ou crise "
        "sanitaire. Elle combine des compétences en droit social, "
        "communication de crise, négociation, et management de "
        "l\'incertitude. Un plan de crise RH structuré permet de "
        "préserver l\'activité, de limiter les dégâts sociaux et "
        "réputationnels, et de préparer la phase de rebond.",
    keyConcepts: [
      'Crise RH et plan de continuité',
      'Communication de crise',
      'Plan social d\'urgence',
      'Cellule de crise RH',
      'Chômage partiel et activité partielle',
      'Rétention des talents en période de crise',
      'Gestion du stress et des RPS en crise',
      'Dialogue social en urgence',
      'Rebond post-crise et résilience organisationnelle',
      'Gestion des départs massifs (Bumping)',
    ],
    sections: [
      ResourceSection(
        title: '1. La cellule de crise RH',
        content: "La cellule de crise RH est activée immédiatement en "
            "situation d\'urgence. Elle est composée du DRH, du "
            "responsable juridique, du responsable communication, "
            "d\'un représentant de la DAF, et d\'un psychologue du "
            "travail. Elle se réunit quotidiennement et rend compte "
            "au COMEX de crise. Ses missions : évaluer l\'impact "
            "social, coordonner les actions d\'urgence, préparer les "
            "communications, et anticiper les scénarios.",
      ),
      ResourceSection(
        title: '2. Plan d\'action d\'urgence (0-30 jours)',
        content: "La phase d\'urgence vise à stabiliser la situation : "
            "(1) gestion immédiate du conflit social (dialogue, "
            "médiation, mesures de rétorsion), (2) communication de "
            "crise interne et externe, (3) identification des "
            "talents critiques à retenir à tout prix, (4) mise en "
            "place du chômage partiel si nécessaire, (5) négociation "
            "d\'un accord de méthode avec les partenaires sociaux. "
            "L\'objectif est de retrouver un minimum de stabilité "
            "pour pouvoir travailler sur le plan de restructuration.",
      ),
      ResourceSection(
        title: '3. Restructuration et plan social',
        content: "La phase de restructuration (1-4 mois) met en œuvre "
            "le plan social : consultation du CSE, élaboration du "
            "PSE, négociation des modalités de départ, et "
            "accompagnement des salariés concernés. Parallèlement, "
            "un plan de rétention des talents critiques est déployé "
            "(primes, formation, perspectives). La communication "
            "interne doit être transparente et empathique pour "
            "maintenir la confiance des salariés restants.",
      ),
      ResourceSection(
        title: '4. Rebond post-crise et résilience',
        content: "La phase de rebond (3-6 mois) prépare l\'avenir : "
            "redéfinition de l\'organisation cible, mise en place "
            "d\'un plan de recrutement sélectif sur les métiers "
            "porteurs, renforcement de la marque employeur, et "
            "déploiement d\'un programme de résilience pour les "
            "salariés (accompagnement psychologique, team building, "
            "projet d\'entreprise). Les leçons de la crise sont "
            "capitalisées dans un retour d\'expérience (REX) qui "
            "alimente le plan de continuité RH.",
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 16. GPEC avancé — Predictive workforce planning avec IA
// ---------------------------------------------------------------------------
final HrTemplate gpecAvance = HrTemplate(
  id: 'gpec_avance',
  title: 'GPEC avancé (Predictive Workforce)',
  description: 'GPEC augmentée par l\'IA et le machine learning',
  level: 'master',
  icon: 'auto_graph',
  role: "Vous êtes le DRH d\'une entreprise du CAC 40 implantée en Afrique de l\'Ouest (1200 salariés).",
  context: "La direction générale vous demande de passer à la vitesse "
      "supérieure en matière de GPEC : utiliser l\'intelligence artificielle "
      "et le machine learning pour anticiper les besoins en compétences "
      "à 5-10 ans. Vous disposez de données RH historiques riches "
      "(15 ans de données) et d\'un budget de 400 millions FCFA pour "
      "le programme. Les enjeux sont multiples : prédire l\'évolution "
      "des métiers face à l\'IA générative, modéliser les scénarios de "
      "transformation, et construire un jumeau numérique (digital twin) "
      "de la population RH. Le Chief Digital Officer est votre sponsor "
      "et le Comex attend un proof of concept dans 6 mois.",
  objectives: [
    'Modéliser l\'évolution des métiers à 10 ans avec des scénarios probabilistes',
    'Développer un modèle prédictif des compétences critiques',
    'Concevoir un jumeau numérique RH (digital twin)',
    'Intégrer l\'IA dans la prise de décision RH stratégique',
  ],
  defaultDurationDays: 14,
  defaultMaxGroups: 4,
  gradingCriteria: [
    CriteriaDef(name: 'Modélisation et scénarios', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Innovation technologique', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Qualité des données et biais', maxScore: 10, coefficient: 2),
    CriteriaDef(name: 'Faisabilité et budget', maxScore: 10, coefficient: 1),
  ],
  decisionParams: [
    DecisionParam(
      id: 'budget_ia_gpec',
      label: 'Budget IA / GPEC avancée',
      description: 'Budget total du programme IA GPEC avancée',
      type: DecisionType.currency,
      min: 100000000,
      max: 400000000,
      defaultValue: 250000000,
      step: 25000000,
    ),
    DecisionParam(
      id: 'horizon_prediction',
      label: 'Horizon de prédiction',
      description: 'Nombre d\'années pour les projections prédictives',
      type: DecisionType.integer,
      min: 3,
      max: 15,
      defaultValue: 8,
      step: 1,
    ),
    DecisionParam(
      id: 'niveau_autonomie_ia',
      label: 'Niveau d\'autonomie de l\'IA',
      description: '0 = Aide à la décision (recommandations), 50 = Semi-autonome, 100 = Fully autonomous',
      type: DecisionType.percentage,
      min: 0,
      max: 100,
      defaultValue: 50,
      step: 25,
    ),
    DecisionParam(
      id: 'taille_equipe_data_rh',
      label: 'Taille équipe Data RH',
      description: 'Nombre de spécialistes data/IA dédiés à la GPEC avancée',
      type: DecisionType.integer,
      min: 2,
      max: 15,
      defaultValue: 5,
      step: 1,
    ),
  ],
  successMetrics: [
    SuccessMetric(
      id: 'precision_predictive',
      label: 'Précision prédictive à 2 ans',
      unit: '%',
      description: 'Taux de précision du modèle sur les effectifs réels',
    ),
    SuccessMetric(
      id: 'couverture_scenarios',
      label: 'Couverture des scénarios',
      unit: '%',
      description: '% des métiers couverts par des modèles prédictifs',
    ),
    SuccessMetric(
      id: 'adoption_ia_rh',
      label: 'Taux d\'adoption des décisions IA',
      unit: '%',
      description: '% des décisions RH intégrant les recommandations du modèle',
    ),
  ],
  decisionPeriods: 5,
  rules: [
    '5 périodes = 5 ans (annuelles)',
    'Période 1 = Proof of Concept, Périodes 2-3 = Déploiement, Périodes 4-5 = Optimisation',
  ],
  constraints: [
    'Budget total = 400 millions FCFA sur 5 ans',
    'Le modèle doit être explicable (Explainable AI) pour être conforme RGPD',
    'Toute décision RH automatisée doit avoir une validation humaine possible',
  ],
  resourceContent: ResourceContent(
    summary: "La GPEC avancée ou « Workforce Planning 4.0 » intègre "
        "l\'intelligence artificielle, le machine learning et la "
        "modélisation prédictive pour anticiper les besoins en "
        "compétences avec une précision inédite. Elle permet de "
        "simuler des scénarios complexes (fusion, digitalisation, "
        "crise) et d\'optimiser les décisions RH en continu. Le "
        "jumeau numérique RH (Digital Twin) est la représentation "
        "virtuelle de la population de l\'entreprise, permettant "
        "de tester des politiques RH dans un environnement simulé.",
    keyConcepts: [
      'Workforce planning 4.0',
      'Digital twin RH',
      'Machine learning prédictif (Random Forest, XGBoost, LSTM)',
      'Scénarios probabilistes et Monte Carlo',
      'Explainable AI (XAI) pour les RH',
      'Analyse des écarts compétences augmentée',
      'Skill ontology et taxonomie IA',
      'Modélisation des flux de main-d\'œuvre',
      'Recommandation automatique de formation',
      'Éthique algorithmique en GPEC',
    ],
    sections: [
      ResourceSection(
        title: '1. Du reporting à la prédiction : l\'évolution du workforce planning',
        content: "Le workforce planning a connu trois révolutions : "
            "WP 1.0 (tableaux de bord historiques), WP 2.0 (analytique "
            "descriptive et segmentation), et WP 3.0/4.0 (prédictif "
            "et prescriptif). La GPEC avancée utilise des modèles "
            "de machine learning (Random Forest, Gradient Boosting, "
            "réseaux de neurones LSTM) pour prédire les flux de "
            "personnel (embauches, départs, promotions) et les "
            "écarts de compétences à horizon 5-10 ans. Les modèles "
            "sont entraînés sur les données historiques internes "
            "et enrichis de données externes (marché de l\'emploi, "
            "PIB, inflation).",
      ),
      ResourceSection(
        title: '2. Le jumeau numérique RH (Digital Twin)',
        content: "Le Digital Twin RH est une représentation virtuelle "
            "de la force de travail qui reproduit les comportements "
            "individuels et collectifs. Il permet de simuler l\'impact "
            "de décisions RH avant leur déploiement réel : « Que se "
            "passerait-il si nous augmentons le budget formation de "
            "20% ? », « Quel est l\'effet d\'un nouveau système de "
            "rémunération sur le turnover ? ». Le jumeau numérique "
            "utilise des modèles multi-agents (ABM) et des réseaux "
            "bayésiens pour modéliser les interactions complexes "
            "entre les individus, les équipes et l\'organisation.",
      ),
      ResourceSection(
        title: '3. Ontologie des compétences et IA',
        content: "La taxonomie des compétences (skill ontology) est le "
            "fondement de la GPEC avancée. L\'IA permet de construire "
            "automatiquement cette ontologie en analysant les CV, "
            "les fiches de poste, les évaluations, et les données "
            "de formation. Le NLP (Natural Language Processing) "
            "extrait les compétences implicites et explicites. "
            "Les modèles de recommandation suggèrent des parcours "
            "de formation personnalisés pour combler les écarts "
            "identifiés. La cartographie des compétences est "
            "mise à jour en temps réel via l\'apprentissage continu.",
      ),
      ResourceSection(
        title: '4. Gouvernance, éthique et limites',
        content: "La GPEC pilotée par l\'IA soulève des enjeux éthiques "
            "spécifiques : biais algorithmiques (les données "
            "historiques reflètent des discriminations passées), "
            "transparence des décisions (droit à l\'explication), "
            "et protection des données (RGPD). Un comité d\'éthique "
            "des données RH doit valider chaque modèle avant "
            "déploiement. La supervision humaine reste obligatoire "
            "pour les décisions impactant les carrières. Le ROI "
            "de la GPEC avancée se mesure en réduction du "
            "time-to-hire, en adéquation compétences améliorée, "
            "et en optimisation de la masse salariale.",
      ),
    ],
  ),
);

// =============================================================================
// Liste complète des templates Master
// =============================================================================
final List<HrTemplate> masterTemplates = [
  gpec,
  remuneration,
  strategieRh,
  gestionTalents,
  conduiteChangement,
  relationsSociales,
  sirh,
  auditRh,
  mobiliteCarrieres,
  managementInterculturel,
  rseRh,
  controleGestionSocial,
  droitSocialAvance,
  hrAnalytics,
  gestionCrisesRh,
  gpecAvance,
];
