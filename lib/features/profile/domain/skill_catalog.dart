/// Domains and skills offered in the skill picker. Interviewers can also type
/// a skill that isn't listed. Replace with an API-driven list when the
/// backend provides one.
abstract final class SkillCatalog {
  static const Map<String, List<String>> domains = {
    'Mobile': [
      'Flutter & Dart',
      'Android (Kotlin)',
      'iOS (Swift)',
      'React Native',
    ],
    'Frontend': [
      'React',
      'Angular',
      'Vue.js',
      'TypeScript',
      'HTML & CSS',
    ],
    'Backend': [
      'Java & Spring Boot',
      'Node.js',
      'Python (Django / FastAPI)',
      'Go',
      '.NET (C#)',
      'Ruby on Rails',
    ],
    'Data & AI': [
      'Machine Learning',
      'Data Engineering',
      'SQL & Databases',
      'Data Science',
      'LLM Applications',
    ],
    'Cloud & DevOps': [
      'AWS',
      'Microsoft Azure',
      'Google Cloud',
      'Kubernetes & Docker',
      'CI/CD',
    ],
    'Quality': [
      'Test Automation',
      'Manual QA',
      'Performance Testing',
    ],
    'Architecture': [
      'System Design',
      'Distributed Systems',
      'Security',
    ],
    'Leadership': [
      'Engineering Management',
      'Product Management',
      'Behavioural Interviews',
    ],
  };

  static List<String> get domainNames => domains.keys.toList();

  static List<String> skillsFor(String domain) => domains[domain] ?? const [];
}
