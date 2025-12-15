# TODO - Plugin K9s per Monitoring e Troubleshooting

## 🔍 Troubleshooting & Diagnostics

### ✅ Implementati
- [x] **KRR Namespace** (Shift-K) - Raccomandazioni risorse per namespace
- [x] **Scale Zero** (Shift-Z) - Scala a zero deployment/statefulset
- [x] **HolmesGPT** (Shift-H) - AI assistant per troubleshooting
- [x] **Trace DNS** (Shift-T) - Tracciamento richieste DNS
- [x] **Debug Pod** (Shift-D) - Container netshoot per debugging

### 📋 Da Implementare

#### 1. Pod Health Check (Shift-P)
**Priorità: Alta**
- Mostra eventi recenti del pod
- Restart count e motivi
- Resource usage vs limits (CPU/Memory)
- Status readiness/liveness probes
- Output colorato con problemi in rosso
- **Use case**: Diagnostica rapida pod problematici

#### 2. Network Debugger (Shift-N)
**Priorità: Alta**
- Ephemeral container con nicolaka/netshoot
- Test connettività: DNS, endpoints interni, ping
- Check porte aperte
- Traceroute verso servizi
- nslookup automatico per service discovery
- **Use case**: Debug problemi di rete

#### 3. Events Timeline (Shift-E)
**Priorità: Media**
- Eventi ultimi 5-10 minuti per namespace/pod
- Filtrati per Warning/Error
- Formattazione colorata per tipo
- Ordinati per timestamp
- **Use case**: Vedere cosa è successo recentemente

#### 4. Resource Hog Finder (Shift-R)
**Priorità: Media**
- Top pods per CPU/Memory nel namespace
- Confronto usage vs requests/limits
- Identifica pod che superano i limiti
- Suggerimenti ottimizzazione
- **Use case**: Trovare pod che consumano troppo

#### 5. Quick Logs Analyzer (Shift-L)
**Priorità: Bassa**
- Ultimi 100 log con grep per ERROR/WARN/FATAL
- Conta occorrenze per tipo errore
- Mostra stack traces se presenti
- Pattern matching per errori comuni
- **Use case**: Analisi rapida errori nei log

---

## 🚀 Automation & Quick Actions

#### 6. Pod Restarter (Shift-X)
**Priorità: Alta**
- Restart rapido con `kubectl rollout restart`
- Conferma visiva prima dell'azione
- Mostra progressione rollout
- Verifica nuovo pod è healthy
- **Use case**: Restart veloce senza kubectl

#### 7. Port Forward Manager (Shift-F)
**Priorità: Media**
- Setup rapido port-forward per pod/service
- Lista porte comuni (80, 443, 8080, 3000, 5000, 9090)
- Background mode con PID tracking
- Kill port-forward esistenti
- **Use case**: Accesso rapido a servizi interni

#### 8. Secret/ConfigMap Viewer (Shift-S)
**Priorità: Alta**
- Decode base64 secrets (con conferma per sicurezza)
- Pretty-print JSON/YAML configs
- Mostra quali pod usano quale secret/configmap
- Diff tra versioni
- **Use case**: Verificare configurazioni senza kubectl

#### 9. Exec Shell Picker (Shift-B)
**Priorità: Media**
- Scelta rapida shell (bash/sh/ash/zsh)
- Auto-detect quale shell è disponibile
- Opzione per cambiare user (es. root)
- History dei comandi precedenti
- **Use case**: Shell migliore del default k9s

---

## 📊 Monitoring & Insights

#### 10. Pod Cost Estimator (Shift-C)
**Priorità: Bassa**
- Calcola costo stimato basato su CPU/Memory requests
- Confronta con actual usage (identifica sprechi)
- Report aggregato per namespace
- Risparmio potenziale
- **Use case**: Cost optimization

#### 11. Service Mesh Inspector (Shift-M)
**Priorità: Bassa**
- Per Istio/Linkerd: status sidecar, traffic stats
- Certificati mTLS e scadenza
- Latency metrics rapide
- Configurazione virtual services
- **Use case**: Debug service mesh

#### 12. Image Vulnerability Scanner (Shift-V)
**Priorità: Media**
- Usa trivy per scan rapido immagini
- Mostra CVE critiche e HIGH
- Suggerisce versioni più sicure
- Cache risultati per performance
- **Use case**: Security check rapido

#### 13. Pod Dependencies Mapper (Shift-G)
**Priorità: Media**
- Mostra ConfigMaps, Secrets, PVCs usati
- ServiceAccount e RBAC associati
- Network Policies che influenzano il pod
- Grafo dipendenze visuale
- **Use case**: Capire impatto modifiche

---

## 🛠️ Operations

#### 14. Backup Creator (Shift-Y)
**Priorità: Alta**
- Backup rapido YAML manifests (deployment, service, ingress, etc.)
- Salva in directory con timestamp
- Opzione backup namespace completo
- Restore rapido da backup
- **Use case**: Backup prima di modifiche rischiose

#### 15. Diff Checker (Shift-I)
**Priorità: Media**
- Confronta configurazione live vs file YAML
- Evidenzia drift configuration
- Mostra cosa cambierebbe un kubectl apply
- Integrazione con git diff
- **Use case**: Verificare drift da IaC

#### 16. Quick Rollback (Shift-U)
**Priorità: Alta**
- Lista ultimi 5 rollout revision
- Rollback rapido a versione precedente
- Preview differenze tra revisioni
- Conferma prima del rollback
- **Use case**: Rollback veloce dopo deploy problematico

#### 17. Node Drain Helper (Shift-O)
**Priorità: Bassa**
- Drain node con opzioni comuni pre-configurate
- Mostra pod che verranno spostati
- Cordon/Uncordon rapido
- Verifica capacità altri nodi
- **Use case**: Manutenzione nodi

---

## 🔐 Security & Compliance

#### 18. RBAC Checker (Shift-A)
**Priorità: Media**
- Mostra permessi effettivi del ServiceAccount
- "Can I?" checker rapido (can-i per varie risorse)
- Identifica privilegi eccessivi
- Suggerimenti least privilege
- **Use case**: Audit permessi

#### 19. Network Policy Tester (Shift-Q)
**Priorità: Bassa**
- Test connettività tra pods considerando NetworkPolicies
- Mostra regole che bloccano/permettono
- Suggerisce policy mancanti
- Simulazione traffico
- **Use case**: Debug network policies

#### 20. Security Context Analyzer (Shift-J)
**Priorità: Media**
- Verifica best practices (non-root, readOnlyRootFilesystem, etc.)
- Security score per pod (0-100)
- Suggerimenti miglioramenti sicurezza
- Compliance check (PSS/PSA)
- **Use case**: Security hardening

---

## 📝 Note Implementazione

### Shortcut Disponibili
- Shift-A, Shift-B, Shift-C, Shift-E, Shift-F, Shift-G, Shift-I, Shift-J
- Shift-L, Shift-M, Shift-N, Shift-O, Shift-P, Shift-Q, Shift-R
- Shift-S, Shift-U, Shift-V, Shift-X, Shift-Y

### Shortcut Già Usati
- Shift-D: Debug Pod / Helm Diff
- Shift-H: HolmesGPT
- Shift-K: KRR
- Shift-T: Trace DNS
- Shift-W: CRD Wizard
- Shift-Z: Scale Zero

### Priorità Implementazione Suggerita
1. **Pod Health Check** (facile, molto utile)
2. **Secret/ConfigMap Viewer** (facile, uso frequente)
3. **Backup Creator** (facile, safety net)
4. **Events Timeline** (facile, troubleshooting)
5. **Pod Restarter** (facile, operazioni comuni)
6. **Quick Rollback** (medio, critico per production)
7. **Resource Hog Finder** (medio, ottimizzazione)
8. **Network Debugger** (medio, troubleshooting complesso)

### Tool Esterni Richiesti
- **trivy**: Image scanning (#12)
- **nicolaka/netshoot**: Network debugging (#2)
- **jq**: JSON parsing (vari)
- **yq**: YAML parsing (vari)
