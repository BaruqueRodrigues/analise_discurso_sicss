library(tidyverse)

# get data ----------------------------------------------------------------

discursos <- speechbr::speech_data(keyword = "",
                      start_date = "2023-01-01",
                      end_date = "2023-12-31")

write_rds(discursos, "data/discursos.rds")

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
  

 
dados <- left_join(discursos, dep_2022,
            by = c("orador" = "nm_candidato"))

dados %>% 
  write_rds("data/dataset_final.rds")
