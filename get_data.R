library(tidyverse)

# Get data ----------------------------------------------------------------


# pegando as informações dos dep na api -----------------------------------

# baixando as info dos deputados na api
deputados <- readr::read_csv2("https://dadosabertos.camara.leg.br/arquivos/deputados/csv/deputados.csv")


# pegando os discursos na api

future::multiprocess(8)

teste <- furrr::future_map(paste0(deputados %>%
                             filter(idLegislaturaFinal == 57) %>%
                             pull(uri),
                           "/discursos?idLegislatura=57"), ~
      .x %>% 
      jsonlite::fromJSON())

# Enriquecendo os dados dos discursos com as info dos candidatos na api

discursos <- teste %>% 
  tibble(data =.) %>% 
  unnest_wider(data) %>% 
  unnest_longer(dados) %>%
  unnest(links) %>% 
  select(-rel) %>% 
  mutate(href = str_remove_all(href, "https://dadosabertos.camara.leg.br/api/v2/deputados/") %>% 
           str_extract("\\d{6}")) %>% 
  rename(cod_dep = href) %>% 
  unnest() %>% 
  janitor::clean_names() %>% 
  left_join(
    deputados %>%
      filter(idLegislaturaFinal == 57) %>% 
      mutate(uri = str_remove_all(uri, "https://dadosabertos.camara.leg.br/api/v2/deputados/") %>% 
               str_extract("\\d{6}")) %>% 
      select(cod_dep = uri, nome, nomeCivil, siglaSexo, cpf),
    multiple = "first"
    
  )

# Escrevendo os dados dos discursos em .rds
write_rds(discursos, "data/discursos.rds")


# Pegando as informações dos candidatos no TSE
dep_2022 <- electionsBR::candidate_fed(2022) %>% 
  filter(DS_CARGO == "DEPUTADO FEDERAL",
         DS_SIT_TOT_TURNO %in% c("ELEITO",
                                 "ELEITO POR QP",
                                 "ELEITO POR MÉDIA")
  )  %>% janitor::clean_names() %>%
  select(
    nm_candidato, nr_cpf_candidato, ds_cor_raca, ds_genero,
    sg_uf,sg_uf_nascimento,
    sg_partido,sg_federacao,dt_nascimento,
    ds_grau_instrucao,ds_estado_civil, ds_ocupacao,
    st_reeleicao)

# Enriquecendo os dados
dataset_final <- discursos %>% 
  left_join(dep_2022,
            by = c("nomeCivil" = "nm_candidato")) 

dataset_final %>% 
  write_rds("data/dataset_final.rds")








